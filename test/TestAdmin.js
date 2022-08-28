const Admin = artifacts.require("Admin");

require('chai')
 .use(require('chai-as-promised'))
 .should();

//const chai = require("chai");
//const ChaiTruffle = require("chai-truffle");
//chai.use(ChaiTruffle);

// testing the deplyment process
contract('Admin', function (accounts) {

  it("Basic Contract Deployment", async function () {
    const admin = await Admin.new(7);
    assertCorrectAddress(admin.address);

    const adminList = await admin.getAdmin();
    checkAdminList(adminList, 1);
    
    assert.equal(await admin.DAY(), 86400);
    assert.equal(await admin.libraryAddress(), 0);
    assert.equal(await admin.treasuryAddress(), 0);
    assert.equal(await admin.votePeriod(), 7);
    assert.equal(await admin.minVotePeriod(), 7);
    for (let i = 0; i < 10; i++) {
      assertVoteNotInitialised(await admin.votes(i));
    }
  });

  it("Testing AddVote", async function () {
    const admin = await Admin.new(7);
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
}
);


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

