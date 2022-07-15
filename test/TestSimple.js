const Simple = artifacts.require("Simple");

// write truffle js test for Simple.sol
contract('Simple', function (accounts) {
  it("should deploy a contract", async function () {
    const simple = await Simple.new();
    assert.ok(simple.address);
    assert.equal(await simple.getX(), 0);
    await simple.setX(3);
    assert.equal(await simple.getX(), 3);
  });
}
);

