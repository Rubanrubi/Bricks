const chai = require('chai')
const Bricks = artifacts.require('../contracts/Bricks.sol');
const expect = chai.expect;
const truffleAssert = require('truffle-assertions');
const Web3 = require('web3');
let web3 =  new Web3('HTTP://127.0.0.1:8545');

contract('Bricks',accounts => {

    let bricks;
    const sender = accounts[0];
    const recipient = accounts[1];

    beforeEach(async () => {
        bricks = bricks.deployed();
    })

    describe('Fee Section',()=>{

        it('Enable Fee from non owner - fails', async () => {
            const enableTax = true;
            try{
                let fee = await bricks.setEnableFee(enableTax,{from: recipient});
                truffleAssert.eventEmitted(fee,'EnableFee', async(ev) =>{
                    return ev.enableTax = enableTax;
                })
            }catch(err){
                const errorMessage = "Ownable: caller is not the owner"
                assert.equal(err.reason, errorMessage, "Fee Should be Enabled by owner");
            }
        });

        it('Enable Fee from owner', async () => {
            const enableTax = true;
            let fee = await bricks.setEnableFee(enableTax,{from: sender});
            truffleAssert.eventEmitted(fee,'EnableFee', async(ev) =>{
                return ev.enableTax = enableTax;
            })
        })

        it('No tax after disable fee (Including Development & Team Wallet)', async () => {
            const enableTax = false;
            const amount = 100 * 10 ** 9;
            await bricks.setEnableFee(enableTax,{from: sender});
            let transfer = await bricks.transfer(recipient,amount,{from:sender})
            truffleAssert.eventEmitted(transfer,'Transfer', async(ev) =>{
                assert.equal(amount, ev.value, "Recipient got full amount without tax");
                return ev.from == sender
                && ev.to == recipient
                && ev.value == amount;
            })
        })


        it('Enable fee', async () => {
            const enableTax = true;
            let fee = await bricks.setEnableFee(enableTax,{from: sender});
            truffleAssert.eventEmitted(fee,'EnableFee', async(ev) =>{
                return ev.enableTax = enableTax;
            })
        })

        it('Tax applies if fee enabled (Including Development & Team Wallet)',() => {
            const enableTax = true;
            let beforeTxBalance;
            let afterTxBalance;
            const amount = 100 * 10 ** 9;

            await bricks.setEnableFee(enableTax,{from: sender});

            // Before transaction balance checking for recipient.
            let balanceBeforeTransfer = await bricks.balanceOf(recipient);
            truffleAssert.eventEmitted(balanceBeforeTransfer,'Balance', async(ev) =>{
                beforeTxBalance = ev.account;
            })

            let transfer = await bricks.transfer(recipient,amount,{from:sender})
            truffleAssert.eventEmitted(transfer,'Transfer', async(ev) =>{
                assert.equal(amount, ev.value, "Recipient got amount with tax");
                return ev.from == sender
                && ev.to == recipient
                && ev.value == 94 * 10 ** 9;
            })

            // After transaction recipient account should take redistribution,development,team taxes.
            let balanceAfterTransfer = await bricks.balanceOf(recipient);
            truffleAssert.eventEmitted(balanceAfterTransfer,'Balance', async(ev) =>{
                afterTxBalance = ev.rAmount;
            })
        })

    })

    describe('AntiWhale Section', () => {

        it('Enable/Disable Antiwhale from non owner -fails', async () => {
            const antiWhale = true;
            try{
                let fee = await bricks.setAntiwale(antiWhale,{from: recipient});
                truffleAssert.eventEmitted(fee,'AntiWhale', async(ev) =>{
                    return ev.enableAntiwale = antiWhale;
                })
            }catch(err){
                const errorMessage = "Ownable: caller is not the owner"
                assert.equal(err.reason, errorMessage, "Anti Whale Should be Enabled by owner");
            }
        })

        it('Enable/Disable Antiwhale from owner',() => {

        })

        it('If AntiWhale enable need to restrict bulk transfer limit as 20000000',() => {

        })

        it('if antiwale is disabled above the limit (20000000) also possible to transfer',() => {

        })

    })
})