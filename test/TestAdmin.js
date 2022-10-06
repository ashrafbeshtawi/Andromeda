const { assert } = require('chai');

// config
const MIN_VOTING_PERIOD = 0;
const DEFAULT_VOTING_PERIOD = 7;
const DEFAULT_STABLE_BALANCE_PERIOD = 7;
const EXCLUDED_TEST_IDS = [1, 2, 3, 4];
const DAY = 86400;


const Admin = artifacts.require("Admin");
require('chai')
 .use(require('chai-as-promised'))
 .should();

// testing the deployment process
contract('Admin', function (accounts) {

  it("Basic Contract Deployment", async function () {
    const id = 1;
    if (checkIsTestExcluded(id)) {
      return;
    }

    const admin = await Admin.new(DEFAULT_VOTING_PERIOD, DEFAULT_STABLE_BALANCE_PERIOD);
    assertCorrectAddress(admin.address);

    const adminList = await admin.getAdmin();
    checkAdminList(adminList, 1);
    
    assert.equal(await admin.DAY(), 86400);
    assert.equal(await admin.libraryAddress(), 0);
    assert.equal(await admin.treasuryAddress(), 0);
    assert.equal(await admin.votePeriod(), DEFAULT_VOTING_PERIOD);
    assert.equal(await admin.minVotePeriod(), DEFAULT_VOTING_PERIOD);
    for (let i = 0; i < 10; i++) {
      assertVoteNotInitialised(await admin.votes(i));
    }
  });

  it("Testing AddVote basic", async function () {
    const id = 2;
    if (checkIsTestExcluded(id)) {
      return;
    }

    const admin = await Admin.new(DEFAULT_VOTING_PERIOD, DEFAULT_STABLE_BALANCE_PERIOD);
    // call as not admin
    await admin.addVote(accounts[1], 1, 1, {from: accounts[2]}).should.be.rejectedWith('Only admin can add vote');
    // call as short voting period
    await admin.addVote(accounts[1], 1, 6, {from: accounts[0]}).should.be.rejectedWith('Voting period is too short');
    // Adding 10 votes then try to add extra one and expect error
    for (let i = 0; i < 10; i++) {
      await admin.addVote(accounts[1], 1, 10, {from: accounts[0]})
    }
    await admin.addVote(accounts[1], 1, 10, {from: accounts[0]}).should.be.rejectedWith('No free vote index')
  });

  it("Testing AddVote voting period", async function () {
    const id = 3;
    if (checkIsTestExcluded(id)) {
      return;
    }
    const admin = await Admin.new(DEFAULT_VOTING_PERIOD, DEFAULT_STABLE_BALANCE_PERIOD);
    await admin.addVote(accounts[1], 1, DEFAULT_VOTING_PERIOD, {from: accounts[0]})
    const event = await admin.getPastEvents('VoteCreated', {fromBlock:0, toBlock:'latest'});
    assert.equal(event.length, 1);
    const indexOfVote = parseInt(event[0].returnValues.index);
    const createdVote = await admin.votes(indexOfVote);
    const startDate = createdVote.startDate.toNumber();
    const endDate = createdVote.endDate.toNumber();
    assert.equal(endDate, startDate + (DEFAULT_VOTING_PERIOD * DAY))
  });

  it("Testing AddVote/ResolveVote Errors", async function () {
    const id = 4;
    if (checkIsTestExcluded(id)) {
      return;
    }
    const admin = await Admin.new(DEFAULT_VOTING_PERIOD, DEFAULT_STABLE_BALANCE_PERIOD);
    const indexOfVote = await addVote(admin, accounts[1], 1, DEFAULT_VOTING_PERIOD, accounts)
    await admin.resolveVote(indexOfVote).should.be.rejectedWith('Vote has not ended')
    await admin.resolveVote(indexOfVote + 1).should.be.rejectedWith('Vote is not initialized')
  });

  it("Testing Vote", async function () {
    const id = 5;
    if (checkIsTestExcluded(id)) {
      return;
    }

    const admin = await Admin.new(MIN_VOTING_PERIOD, DEFAULT_STABLE_BALANCE_PERIOD);
    await admin.resolveVote(0).should.be.rejectedWith('Vote is not initialized')

    const indexOfVote = await addVote(admin, accounts[1], 1, DEFAULT_VOTING_PERIOD, accounts)
    await checkVoteState(admin, indexOfVote, 0, 0, accounts[0], 0);
    //await admin.vote(indexOfVote, 0);
    //await admin.votes(indexOfVote).NumberOfApprovals
    //const event = await admin.getPastEvents('Voted', {fromBlock:0, toBlock:'latest'});
    //console.log(parseInt(event[0].returnValues));
    //console.log(result);

  });
}
);

// add vote & return its id
async function addVote(contract, targetAddress, target, votingPeriod, accounts) {
  await contract.addVote(targetAddress, target, votingPeriod, {from: accounts[0]})
  const event = await contract.getPastEvents('VoteCreated', {fromBlock:0, toBlock:'latest'});
  return parseInt(event[0].returnValues.index);
}

async function checkVoteState(contract, indexOfVote, approvals, disapprovals, address, stateOfAddress) {
  const vote = await contract.votes(indexOfVote);
  const NumberOfApprovals = vote.NumberOfApprovals.toNumber();
  const NumberOfDisapprovals = vote.NumberOfDisapprovals.toNumber();
  const adressState = 0;//vote.voters[address];
  console.log('testing', NumberOfApprovals, NumberOfDisapprovals, adressState);

}

// checks that a given address is defined and not null
function assertCorrectAddress(address) {
  assert.notEqual(address, '');
  assert.notEqual(address, undefined);
  assert.notEqual(address, null);
  assert.notEqual(address, 0);
}

// checks length and content of the admin's list
function checkAdminList(list, numberOfAdmins) {
  assert.equal(list.length, 10);
  for (let i = 0; i < numberOfAdmins; i++) {
    assertCorrectAddress(list[i]);
  }
  for (let i = numberOfAdmins; i < list.length; i++) {
    assert.equal(list[i], 0);
  }
}

// makes sure that a given vote is not initialised
function assertVoteNotInitialised(vote) {
  const id = vote.id.toNumber();
  const targetAddress = vote.targetAddress;
  const votingPeriod = vote.votingPeriod.toNumber();
  const target = vote.target.toNumber();
  const NumberOfApprovals = vote.NumberOfApprovals.toNumber();
  const NumberOfDisapprovals = vote.NumberOfDisapprovals.toNumber();
  const startDate = vote.startDate.toNumber();
  const endDate = vote.endDate.toNumber();
  assert.equal(id, 0);
  assert.equal(targetAddress, 0);
  assert.equal(votingPeriod, 0);
  assert.equal(target, 0);
  assert.equal(NumberOfApprovals, 0);
  assert.equal(NumberOfDisapprovals, 0);
  assert.equal(startDate, 0);
  assert.equal(endDate, 0);
}


// checks if test is excluded from execution
function checkIsTestExcluded(id) {
  return EXCLUDED_TEST_IDS.includes(id);
}