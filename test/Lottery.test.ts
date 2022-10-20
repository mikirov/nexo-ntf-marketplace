import { ethers, upgrades} from 'hardhat';
import { Signer } from 'ethers';
import { assert, expect } from 'chai';
import { Lottery, Ticket } from '../typechain-types';


describe('Lottery', async function () {
    let Lottery: Lottery;
    let Ticket: Ticket;

    let ownerAccount: Signer;
    let secondAccount: Signer;

    before(async function () {
        [ownerAccount, secondAccount] = await ethers.getSigners();
        const salt = process.env.SALT || ethers.utils.formatBytes32String("salt");

        const TicketFactory = await ethers.getContractFactory("Ticket");
        Ticket = await TicketFactory.deploy() as Ticket;

        const LotteryFactory = await ethers.getContractFactory("Lottery");
        Lottery = await upgrades.deployProxy(LotteryFactory, [salt, Ticket.address]) as Lottery;
        await Lottery.deployed();
    });

    it('should revert if non-owner tries to mint a ticket', async function () {
        const secondAccountAddress = await secondAccount.getAddress();
        await expect(Ticket.connect(secondAccount).mint(ethers.BigNumber.from("123"), secondAccountAddress)).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it('should award surprise winner before lottery period has expired', async function () {
        await Lottery.buy()
        await Lottery.awardSurpriseWinner();
        expect()
    });    

});
