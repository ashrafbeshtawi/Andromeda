const Admin = artifacts.require("Admin");

// write truffle js test for Simple.sol
contract('Admin', function (accounts) {
  it("should deploy a contract", async function () {
    const admin = await Admin.new();
    assert.ok(admin.address);
    console.log(await admin.getAdmin());
    //await simple.setX(3);
    //assert.equal(await simple.getX(), 3);
  });
}
);

