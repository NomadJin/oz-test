const {
  accounts,
  contract
} = require('@openzeppelin/test-environment');
const {
  expect
} = require('chai');
const TestHelper = require("./helpers");
// Import utilities from Test Helpers
const {
  BN,
  expectEvent,
  expectRevert
} = require('@openzeppelin/test-helpers');

const DataTraceability = contract.fromArtifact('DataTraceability');

describe('DataTraceability', function () {

  const [owner] = accounts;

  const nullAddress = '0x0000000000000000000000000000000000000000';

  const dataInfo = {
    dataId: '0x0d742ae27cb91ff52d76856236832c6007b362d4',
    provider: '0x9011275CEea53ed6d50486dE711687026e2A0Ed8',
    genTime: new Date().getTime(),
    hash: '0xc95f091f54568c7837a399a9912319e363860f4fd0db918035111e378d4aaa00',
    generation: 0,
    parentDataId: []
  };

  const traceInfo = {
    traceId: '42',
    accessAction: 0,
    accessTime: new Date().getTime(),
    toAddress: nullAddress,
    fromAddress: nullAddress,
    message: '0xc95f091f54568c7837a399a9912319e363860f4fd0db918035111e378d4aaa00'
  };

  const {
    dataId,
    provider,
    genTime,
    hash,
    generation,
    parentDataId
  } = dataInfo;

  const {
    traceId,
    accessAction,
    accessTime,
    toAddress,
    fromAddress,
    message
  } = traceInfo;

  before(async function () {
    this.contract = await DataTraceability.new({
      from: owner
    });
  });

  it('add minter with data traceability admin', async function () {
    const receipt = await this.contract.addMinter(owner);
    expect(receipt.receipt.status).to.be.true;
  })

  it('create datainfo and check dataId', async function () {
    await this.contract.createDataInfo(dataId, provider, genTime, hash, generation, parentDataId, {
      from: owner
    });
    const resultObj = Object.values(await this.contract.getDataInfo(dataId));
    expect(resultObj[0].toUpperCase()).to.be.equal(dataId.toUpperCase());
  });

  it('should failed create datainfo with duplcate dataId', async function () {
    await TestHelper.expectThrow2(this.contract.createDataInfo(dataId, provider, genTime, hash, generation, parentDataId, {
      from: owner
    }));
    //console.log('receipt', receipt);
    //expect(await this.contract.getDataInfo(dataId)).to.be.equal(dataId);
  });

  it('create traceinfo and check traceId', async function () {
    await this.contract.createTraceInfo(dataId, traceId, accessAction, accessTime, toAddress, fromAddress, message, {
      from: owner
    });
    const resultObj = Object.values(await this.contract.getTraceInfo(traceId));
    console.log(resultObj[0]);
    expect(resultObj[0]).to.be.bignumber.equal(traceId);
  });

  it('should failed create traceinfo with duplcate traceId', async function () {
    await TestHelper.expectThrow2(this.contract.createTraceInfo(dataId, traceId, accessAction, accessTime, toAddress, fromAddress, message, {
      from: owner
    }));
  });
});