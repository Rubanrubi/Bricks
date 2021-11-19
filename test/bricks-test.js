const chai = require('chai').should().assert;
const Bricks = artifacts.require('Bricks');
const truffleAssert = require('truffle-assertions');
const Web3 = require('web3');
let web3 =  new Web3('HTTP://127.0.0.1:8545');

contract('Bricks',accounts => {

    let bricks;
    const sender = accounts[0];
    const recipient = accounts[1];

    beforeEach(async () => {
        bricks = await Bricks.deployed();
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
                // console.log('error response',err);
                const errorMessage = "Ownable: caller is not the owner"
                assert.equal(err.reason, errorMessage, "Fee Should be Enabled by owner");
            }
        });

        it('Enable Fee from owner', async () => {
            const enableTax = true;
            let fee = await bricks.setEnableFee(enableTax,{from: sender});
            assert.equal(fee.receipt.status, enableTax, "Fee Should be Enabled by owner");
        })

        it('No tax after disable fee (Including Development & Team Wallet)', async () => {
            const enableTax = false;
            const amount = 100 * 10 ** 9;
            const txAmount = amount.toString();
            await bricks.setEnableFee(enableTax,{from: sender});
            let transfer = await bricks.transfer(recipient,txAmount,{from:sender})
            truffleAssert.eventEmitted(transfer,'Transfer', async(ev) =>{
                assert.equal(txAmount, ev.value, "Recipient got full amount without tax");
                return ev.from == sender
                && ev.to == recipient
                && ev.value == txAmount;
            })
        })


        it('Enable fee', async () => {
            const enableTax = true;
            let fee = await bricks.setEnableFee(enableTax,{from: sender});
            assert.equal(fee.receipt.status, enableTax, "Enabling all fee's");
        })

        it('Tax applies if fee enabled (Including Development & Team Wallet)', async () => {
            const enableTax = true;
            let beforeTxBalance;
            let afterTxBalance;
            const amount = toString(100 * 10 ** 9);
            const txAmount = amount.toString();
            const expectedAmount = toString(94 * 10 ** 9);
            const expectedTxAmount = expectedAmount.toString();

            await bricks.setEnableFee(enableTax,{from: sender});

            // Before transaction balance checking for recipient.
            beforeTxBalance = await bricks.balanceOf(recipient);

            let transfer = await bricks.transfer(recipient,txAmount,{from:sender})
            truffleAssert.eventEmitted(transfer,'Transfer', async(ev) =>{
                // return ev.from == sender
                // && ev.to == recipient
                // && ev.value == expectedTxAmount;
                assert.equal(expectedTxAmount, ev.value, "Recipient got amount with tax");
            })

            // After transaction recipient account should take redistribution,development,team taxes.
            afterTxBalance = await bricks.balanceOf(recipient);
            assert.isAbove(afterTxBalance,beforeTxBalance,'Is Balance is updating or not');
        })

        it('Balance Updating while new transaction', async () => {
            let beforeTxBalance;
            let afterTxBalance;
            const amount = 100 * 10 ** 9;
            const txAmount = amount.toString();
            // Before transaction balance checking for recipient.
            beforeTxBalance = await bricks.balanceOf(recipient);

            // Transfer
            let transfer = await bricks.transfer(recipient,txAmount,{from:sender})
            truffleAssert.eventEmitted(transfer,'Transfer', async(ev) =>{
                assert.equal(txAmount, ev.value, "Transfer Successfully");
            })

             // After transaction recipient account should take redistribution,development,team taxes.
             afterTxBalance = await bricks.balanceOf(recipient);
             assert.isAtLeast(afterTxBalance,beforeTxBalance,'Balance Increase while transfer');
        })

    })

    describe('AntiWhale Section', () => {

        it('Enable/Disable Antiwhale from non owner -fails', async () => {
            const antiWhale = true;
            try{
                let antiwale = await bricks.setAntiwale(antiWhale,{from: recipient});
                truffleAssert.eventEmitted(antiwale,'Enable antiWhale from non-owner ', async(ev) =>{
                    return ev.enableAntiwale = antiWhale;
                })
            }catch(err){
                const errorMessage = "Ownable: caller is not the owner"
                assert.equal(err.reason, errorMessage, "Anti Whale Should be Enabled by owner");
            }
        })

        it('Enable/Disable Antiwhale from owner', async () => {
            const antiWhale = true;
            let fee = await bricks.setAntiwale(antiWhale,{from: sender});
            assert.equal(fee.receipt.status, antiWhale, "Enabling anti whale by owner");

        })

        it('If AntiWhale enable need to restrict bulk transfer limit as 20000000', async () => {
            const antiWhale = true;
            const transferAmount = 20000000 * 10 ** 9;
            const txAmount = transferAmount.toString();
            try{
              // Transfer
              let transfer = await bricks.transfer(recipient,txAmount,{from:sender})
              truffleAssert.eventEmitted(transfer,'Transfer', async(ev) =>{
                return ev.from == sender
                && ev.to == recipient
                && ev.value == txAmount;
              })
            }catch(err){
                const errorMessage = "Transfer amount should not be greater than 20000000";
                assert.equal(err.reason, errorMessage, "AntiWhale Restricts this much amount While Enable");
            }
        })

        it('if antiwale is disabled sender able to transfer above the limit (20000000) also possible', async () => {

            const antiWhale = false;
            const transferAmount = 20000000 * 10 ** 9;
            const txAmount = transferAmount.toString();
              // Transfer
              let transfer = await bricks.transfer(recipient,txAmount,{from:sender})
              truffleAssert.eventEmitted(transfer,'Transfer', async(ev) =>{
                assert.equal(ev.value, txAmount, "AntiWhale does'nt restricts this much amount because disabled");
                return ev.from == sender
                && ev.to == recipient
                && ev.value == txAmount;
              })
        })

    })
})