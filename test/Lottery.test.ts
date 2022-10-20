import { ethers, upgrades } from 'hardhat';
import { Signer } from 'ethers';
import { assert, expect } from 'chai';
import { Lottery, Ticket, PaymentToken } from '../typechain-types';


describe('Lottery', async function () {
    let LotteryProxy: Lottery;
    let Ticket: Ticket;
    let PaymentToken: PaymentToken;

    let ownerAccount: Signer;
    let secondAccount: Signer;
    const getRandomTicketId = () => ethers.BigNumber.from(ethers.utils.randomBytes(32));

    async function signApproval(signer: Signer, value: string): Promise<any> {

        const signerAddress: string = await signer.getAddress();
        const nonce = await PaymentToken.nonces(signerAddress); // Our Token Contract Nonces
        // const nonce = 0;
        console.log(nonce);
        const deadline = + new Date() + 60 * 60; // Permit with deadline which the permit is valid

        const EIP712Domain = [ // array of objects -> properties from the contract and the types of them ircwithPermit
            { name: 'name', type: 'string' },
            { name: 'version', type: 'string' },
            { name: 'verifyingContract', type: 'address' }
        ];

        const domain = {
            name: await PaymentToken.name(),
            version: '1',
            verifyingContract: PaymentToken.address
        };

        const Permit = [ // array of objects -> properties from erc20withpermit
            { name: 'owner', type: 'address' },
            { name: 'spender', type: 'address' },
            { name: 'value', type: 'uint256' },
            { name: 'nonce', type: 'uint256' },
            { name: 'deadline', type: 'uint256' }
        ];

        const message = {
            owner: signerAddress,
            spender: upgrades.erc1967.getImplementationAddress(LotteryProxy.address),
            value: value,
            nonce: nonce,
            deadline
        };

        const data = JSON.stringify({
            types: {
                EIP712Domain,
                Permit
            },
            domain,
            primaryType: 'Permit',
            message
        })

        const signatureLike = await signer.signMessage(data);
        const signature = await ethers.utils.splitSignature(signatureLike);
        console.log(signature);
        return { deadline: deadline, v: signature.v, r: signature.r, s: signature.s };
    }

    before(async function () {
        [ownerAccount, secondAccount] = await ethers.getSigners();
        const salt = process.env.SALT || ethers.utils.formatBytes32String("salt");

        const PaymentTokenFactory = await ethers.getContractFactory("PaymentToken");
        PaymentToken = await PaymentTokenFactory.deploy() as PaymentToken;
        await PaymentToken.deployed();
        console.log("PaymentToken deployed to:", PaymentToken.address);

        const LotteryFactory = await ethers.getContractFactory("Lottery");
        LotteryProxy = await upgrades.deployProxy(LotteryFactory, [salt, PaymentToken.address, ethers.utils.parseEther("2")]) as Lottery;
        await LotteryProxy.deployed();
        console.log("Lottery Proxy deployed to:", LotteryProxy.address);

        Ticket = await ethers.getContractAt("Ticket", await LotteryProxy.ticket(), ownerAccount) as Ticket;
        console.log("Ticket deployed to:", Ticket.address);

        await LotteryProxy.setSaleDuration(60 * 60 * 24 * 7);

        // expect(await LotteryProxy.connect(ownerAccount).owner()).to.equal(await ownerAccount.getAddress());
        expect(await LotteryProxy.connect(ownerAccount).ticket()).to.equal(Ticket.address);
        expect(await LotteryProxy.connect(ownerAccount).paymentToken()).to.equal(PaymentToken.address);
        expect(await LotteryProxy.connect(ownerAccount).ticketPrice()).to.equal(ethers.utils.parseEther("2"));

        await PaymentToken.mint((await ownerAccount.getAddress()), ethers.utils.parseEther("100"));
        await PaymentToken.mint((await secondAccount.getAddress()), ethers.utils.parseEther("100"));

        expect(await PaymentToken.balanceOf(await ownerAccount.getAddress())).to.equal(ethers.utils.parseEther("100"));
        expect(await PaymentToken.balanceOf(await secondAccount.getAddress())).to.equal(ethers.utils.parseEther("100"));
    });

    it('should revert if non-owner tries to mint a ticket', async function () {
        const secondAccountAddress = await secondAccount.getAddress();
        await expect(Ticket.connect(secondAccount).mint(getRandomTicketId(), secondAccountAddress)).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it('should buy a ticket', async function () {
        // const signature = await signApproval(secondAccount, ethers.utils.formatUnits("2", "ether"));
        // await LotteryProxy.connect(secondAccount).buyPermit(getRandomTicketId(), ethers.BigNumber.from(signature.deadline), signature.v, signature.r, signature.s);
        console.log(await upgrades.erc1967.getImplementationAddress(LotteryProxy.address))
        // await PaymentToken.connect(secondAccount).approve(upgrades.erc1967.getImplementationAddress(LotteryProxy.address), ethers.utils.parseEther("2"));
        await PaymentToken.connect(secondAccount).approve(LotteryProxy.address, ethers.utils.parseEther("100"));
        
        // expect(await PaymentToken.allowance(await secondAccount.getAddress(), await upgrades.erc1967.getImplementationAddress(LotteryProxy.address))).to.equal(ethers.utils.parseEther("2"));
        // expect(await PaymentToken.allowance(await secondAccount.getAddress(), await upgrades.erc1967.getImplementationAddress(LotteryProxy.address))).to.equal(await LotteryProxy.connect(ownerAccount).ticketPrice());
        
        expect(await PaymentToken.allowance(await secondAccount.getAddress(), LotteryProxy.address)).to.equal(ethers.utils.parseEther("100"));
        expect(await PaymentToken.allowance(await secondAccount.getAddress(), LotteryProxy.address)).to.be.greaterThanOrEqual(await LotteryProxy.connect(ownerAccount).ticketPrice());
        
        const ticketId = getRandomTicketId();

        await LotteryProxy.connect(secondAccount).buy(ticketId);
        
        expect(await Ticket.ownerOf(ticketId)).to.equal(await secondAccount.getAddress());
        expect(await PaymentToken.balanceOf(await secondAccount.getAddress())).to.equal(ethers.utils.parseEther("98"));
    });

    it('should award the only person who has bought a ticket with half the balance', async function () {
        await LotteryProxy.connect(ownerAccount).awardSurpriseWinner();
        expect(await PaymentToken.balanceOf(await secondAccount.getAddress())).to.equal(ethers.utils.parseEther("99"));
    });

    it('should revert if non-owner tries to award the winner', async function () {
        const ticketId = getRandomTicketId();
        await LotteryProxy.connect(secondAccount).buy(ticketId);

        await expect(LotteryProxy.connect(secondAccount).awardSurpriseWinner()).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it('should revert if owner tries to select the winner before sale ends', async function () {
        expect(await LotteryProxy.connect(ownerAccount).awardSurpriseWinner()).to.be.revertedWithCustomError(LotteryProxy, "TicketSaleNotEnded");
    });

    it('should select winner', async function () {

        const ticketId = getRandomTicketId();
        await LotteryProxy.connect(secondAccount).buy(ticketId);

        /// @dev we are setting the duration to 0 seconds so that we can test this
        await LotteryProxy.connect(ownerAccount).setSaleDuration(ethers.BigNumber.from("0"));
        /// @dev by having only one participant it is guarantted that he will win
        await LotteryProxy.connect(ownerAccount).selectWinner();
        /// @dev we are setting the duration back
        await LotteryProxy.connect(ownerAccount).setSaleDuration(ethers.BigNumber.from("86400"));
        
        /// @dev the second account can then claim the rewards
        expect(await Ticket.balanceOf(await secondAccount.getAddress())).to.equal(ethers.BigNumber.from("1"));
        await LotteryProxy.connect(secondAccount).claimRewards();
        expect(await Ticket.balanceOf(await secondAccount.getAddress())).to.equal(ethers.BigNumber.from("0"));

        expect(await PaymentToken.balanceOf(await secondAccount.getAddress())).to.equal(ethers.utils.parseEther("100"));
        expect(await PaymentToken.balanceOf(LotteryProxy.address)).to.equal(ethers.utils.parseEther("0"));
    });

    it('should change sale duration', async function () {
        await LotteryProxy.connect(ownerAccount).setSaleDuration(1000);
        expect(await LotteryProxy.saleDuration()).to.equal(1000);
    });

    it('should change ticket price', async function () {
        await LotteryProxy.connect(ownerAccount).setTicketPrice(ethers.utils.parseEther("1"));
        expect(await LotteryProxy.ticketPrice()).to.equal(ethers.utils.parseEther("1"));
    });

});
