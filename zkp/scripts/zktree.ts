import * as crypto from 'crypto'
// import * as snarkjs from 'snarkjs'
import { buildMimc7 } from 'circomlibjs'
const BN = require('bn.js');
import { BigNumberish, keccak256 } from 'ethers';
import BigNumber from 'bignumber.js';


const ZERO_VALUE = new BigNumber("21663839004416932945382355908790599225266501822907911457504978515578255421292")

function genRandomNumber(byteCount: number, radix: number) {
    return BigInt('0x' + crypto.randomBytes(byteCount).toString('hex')).toString(radix)
  }
  
  function calculateHash(mimc, left, right) {
    return new BigNumber(mimc.F.toString(mimc.multiHash([left, right])))
}

export async function generateCommitment() {
    const mimc = await buildMimc7();
    const nullifier =genRandomNumber(8, 10)
    const secret =genRandomNumber(8, 10)
    const commitment = mimc.F.toString(mimc.multiHash([nullifier, secret]));
    const nullifierHash = mimc.F.toString(mimc.multiHash([nullifier]));
    return {
        nullifier: nullifier,
        secret: secret,
        commitment: commitment,
        nullifierHash: nullifierHash
    }
}

export function generateZeros(mimc: any, levels: number) {
    let zeros: Array<BigNumber> = []
    zeros[0] = ZERO_VALUE
    for (let i = 1; i <= levels; i++)
        zeros[i] = calculateHash(mimc, zeros[i - 1], zeros[i - 1]);
    return zeros
}



async function main() {
    console.log(await generateCommitment())
}

main() 