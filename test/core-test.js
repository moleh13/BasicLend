const { time } = require("@openzeppelin/test-helpers")
const assert = require("assert")
const BN = require("bn.js")
const { sendEther, pow } = require("./util")

const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F"
const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
const WETH_WHALE = "0xe78388b4ce79068e89bf8aa7f218ef6b9ab0e9d0"
const DAI_WHALE = "0x075e72a5edf65f0a5f44699c7654c1a76941ddc8"

const IERC20 = artifacts.require("IERC20")
const Core = artifacts.require("Core")

const LEND_AMOUNT = pow(10, 18).mul(new BN(1))

contract("Core", (accounts) => {
    const WHALE_1 = WETH_WHALE
    const TOKEN_1 = WETH
    const WHALE_2 = DAI_WHALE
    const TOKEN_2 = DAI
    
    let core
    let token1
    let token2
    beforeEach(async() => {
        await sendEther(web3, accounts[0], WHALE_1, 1)
        await sendEther(web3, accounts[0], WHALE_2, 1)

        core = await Core.new()
        token1 = await IERC20.at(TOKEN_1)
        token2 = await IERC20.at(TOKEN_2)

        const bal1 = await token1.balanceOf(WHALE_1)
        const bal2 = await token2.balanceOf(WHALE_2)
        console.log(`weth whale balance: ${bal1}`)
        console.log(`dai whale balance: ${bal2}`)
        assert(bal1.gte(LEND_AMOUNT), "bal1 < lend")
        assert(bal2.gte(LEND_AMOUNT), "bal1 < lend")
    })

    it("lend", async () => {
        await token1.approve(core.address, LEND_AMOUNT, {
            from: WHALE_1,
        })
        await token2.approve(core.address, LEND_AMOUNT, {
            from: WHALE_2,
        })

        let tx1 = await core.lend(token1, LEND_AMOUNT, {
            from: WHALE_1,
        })
        let tx2 = await core.lend(token2, LEND_AMOUNT, {
            from: WHALE_2,
        })

    })
})
