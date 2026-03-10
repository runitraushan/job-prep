console.log("Hello");

setTimeout(() => {
    console.log("World");
}, 0);

console.log("!");

async function m1() {
  return await 42;
}

function m2() {
    return 8;
}

let a1 = await m1();
let a2 = a1 + m2();
console.log(a2, "dskjfhdks");