import { ethers } from 'hardhat'

async function main() {
  const currentTimestampInSeconds = Math.round(Date.now() / 1000)
  const unlockTime = currentTimestampInSeconds + 60

  const lockedAmount = ethers.parseEther('0.001')

  const lock = await ethers.deployContract('Lock', [unlockTime], {
    value: lockedAmount
  })

  await lock.waitForDeployment()

  console.log(
    `Lock with ${ethers.formatEther(
      lockedAmount
    )}ETH and unlock timestamp ${unlockTime} deployed to ${lock.target}`
  )
  //简单合约 --------------------------------
  //获取合约工厂
  const simpleStorageFactory = await ethers.getContractFactory('SimpleStorage')
  //部署
  const simpleContract = await simpleStorageFactory.deploy()
  //等待部署完成
  await simpleContract.waitForDeployment()
  //输出合约地址
  simpleContract
    .getAddress()
    .then((address) => console.log('SimpleStorage deployed to:address:', address))
  //获取当前值
  const value = await simpleContract.retrieve()
  console.log('SimpleStorage value:', value.toString())
  //设置值
  await simpleContract.store(13)
  //获取当前值
  const newValue = await simpleContract.retrieve()
  console.log('SimpleStorage new value:', newValue.toString())
  //增加人员
  await simpleContract.addPerson('Alice', 18)
  await simpleContract.addPerson('Bob', 20)
  //获取人员信息
  const people = await simpleContract.getPerson()
  console.log('SimpleStorage person:', people)

  function* f(): Generator<number, boolean, boolean> {
    for (let i = 0; true; i++) {
      let reset: boolean = yield i
      if (reset) {
        i = -1
        console.log('--i--:', i)
      }
    }
  }

  let g = f()
  console.log(g.next())
  console.log(g.next())
  console.log(g.next(true))

  function* generatorFn(i: number): Generator<number, number, any> {
    const j = 5 * (yield i * 10)
    const k = yield (2 * j) / 4
    return i + Number(j) + Number(k)
  }

  const gen = generatorFn(10)
  console.log(gen.next(20)) // i=10 { value: 100, done: false }
  console.log(gen.next(10)) //j=50 { value: 25, done: false }
  console.log(gen.next(5)) //k=5  { value: 65, done: true }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exitCode = 1
  })
