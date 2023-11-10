import * as crypto from 'crypto'
// import * as snarkjs from 'snarkjs'
import { Mimc7, buildMimc7 } from 'circomlibjs'
const BN = require('bn.js');
import { BigNumber } from 'ethers';


type commitment = {
    nullifier: string,
    secret: string,
    commitment: string,
    nullifierHash: string
}

const ZERO_VALUE = BigNumber.from('0') 

function genRandomNumber(byteCount: number, radix: number): string {
    return BigInt('0x' + crypto.randomBytes(byteCount).toString('hex')).toString(radix)
  }
  
function calculateHash(mimc: any, left: any, right: any) {
    return mimc.F.toString(mimc.multiHash([left, right]))
}

export async function generateCommitment(): Promise<commitment> {
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
    for (let i = 1; i <= levels; i++) {
        zeros[i] = calculateHash(mimc, zeros[i - 1], zeros[i - 1]);
    }
    return zeros
}

// calculates Merkle root from elements and a path to the given element 
export function calculateMerkleRootAndPath(mimc: Mimc7, levels: number, elements: any, element?: any) {
    const capacity = 2 ** levels
    if (elements.length > capacity) throw new Error('Tree is full')

    const zeros = generateZeros(mimc, levels);
    let layers:Array<any> = []
    layers[0] = elements.slice()
    for (let level = 1; level <= levels; level++) {
        layers[level] = []
        for (let i = 0; i < Math.ceil(layers[level - 1].length / 2); i++) {
            layers[level][i] = calculateHash(
                mimc,
                layers[level - 1][i * 2],
                i * 2 + 1 < layers[level - 1].length ? layers[level - 1][i * 2 + 1] : zeros[level - 1],
            )
        }
    }

    const root = layers[levels].length > 0 ? layers[levels][0] : zeros[levels - 1]

    let pathElements: Array<any> = []
    let pathIndices: Array<any> = []

    if (element) {
        const bne = BigNumber.from(element)
        let index = layers[0].findIndex((e: any) => BigNumber.from(e).eq(bne))
        for (let level = 0; level < levels; level++) {
            pathIndices[level] = index % 2
            pathElements[level] = (index ^ 1) < layers[level].length ? layers[level][index ^ 1] : zeros[level]
            index >>= 1
        }
    }

    return {
        root: root.toString(),
        pathElements: pathElements.map((v) => v.toString()),
        pathIndices: pathIndices.map((v) => v.toString())
    }
}

async function main() {
    const mimc = await buildMimc7();
    const commitment = await generateCommitment()
    const rootAndPath = await calculateMerkleRootAndPath(mimc, 8, [0, 0, 0, commitment.commitment], commitment.commitment)
    console.log(JSON.stringify(commitment))
    console.log(JSON.stringify(rootAndPath))
}

main() 