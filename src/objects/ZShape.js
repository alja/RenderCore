/**
 * Based on ZSprite by Matevz.
 *
 */

import {Mesh} from './Mesh.js';
import {Quad} from './Quad.js';
import {ZShapeBasicMaterial} from '../materials/ZShapeBasicMaterial.js';
import {Vector2} from '../RenderCore.js';
import {Geometry} from './Geometry.js';
import {Float32Attribute, Uint32Attribute} from '../core/BufferAttribute.js';


export class ZShape extends Mesh {
    constructor(geometry = null, material = null) {
        if (geometry === null) {
            /*
            let xy0 = new Vector2(-0.5, 0.5);
            let xy1 = new Vector2(0.5, -0.5);
            geometry = Quad.makeGeometry(xy0, xy1, false, true, false, false);
            */
           geometry = ZShape.makeCubeGeometry();
           console.log("zshape cube geometry ", geometry);
           this._geometry = geometry;
        }

        if (material === null) {
            material = new ZShapeBasicMaterial();
        }
        // MT for Sebastien -- what would be the best way to clone material?
        // ZShapeBasicMaterial.clone_for_outline() seems OK (but one needs to 
        // take care with uniform / texture / instanceData updates).
        let pmat = material.clone_for_picking();
        let omat = material.clone_for_outline();

        //SUPER
        super(geometry, material, pmat, omat);
        this.type = "ZShape";
    }

    static makeCubeGeometry() {
        let cube = new Geometry();
		cube.vertices = Float32Attribute([
			// Front face
			-1.0, -1.0,  1.0,
			1.0, -1.0,  1.0,
			1.0,  1.0,  1.0,
			-1.0,  1.0,  1.0,

			// Back face
			-1.0, -1.0, -1.0,
			-1.0,  1.0, -1.0,
			1.0,  1.0, -1.0,
			1.0, -1.0, -1.0,

			// Top face
			-1.0,  1.0, -1.0,
			-1.0,  1.0,  1.0,
			1.0,  1.0,  1.0,
			1.0,  1.0, -1.0,

			// Bottom face
			-1.0, -1.0, -1.0,
			1.0, -1.0, -1.0,
			1.0, -1.0,  1.0,
			-1.0, -1.0,  1.0,

			// Right face
			1.0, -1.0, -1.0,
			1.0,  1.0, -1.0,
			1.0,  1.0,  1.0,
			1.0, -1.0,  1.0,

			// Left face
			-1.0, -1.0, -1.0,
			-1.0, -1.0,  1.0,
			-1.0,  1.0,  1.0,
			-1.0,  1.0, -1.0
		], 3);


		cube.indices = Uint32Attribute([
			0, 1, 2,      0, 2, 3,    // Front face
			4, 5, 6,      4, 6, 7,    // Back face
			8, 9, 10,     8, 10, 11,  // Top face
			12, 13, 14,   12, 14, 15, // Bottom face
			16, 17, 18,   16, 18, 19, // Right face
			20, 21, 22,   20, 22, 23  // Left face
        ], 1);
        cube.computeVertexNormals();
        
        //per face UVs
        cube.uv = Float32Attribute([
            // Front face
            0.0,  0.0,
            1.0,  0.0,
            1.0,  1.0,
            0.0,  1.0,
            
            // Back face
            1.0, 0.0,
            1.0, 1.0,
            0.0, 1.0,
            0.0, 0.0,
            
            // Top face
            0.0,  0.0,
            0.0,  1.0,
            1.0,  1.0,
            1.0,  0.0,
            
            // Bottom face
            0.0, 1.0,
            1.0, 1.0,
            1.0, 0.0,
            0.0, 0.0,
            
            // Right face
            0.0, 0.0,
            0.0, 1.0,
            1.0, 1.0,
            1.0, 0.0,
            
            // Left face
            1.0, 0.0,
            0.0, 0.0,
            0.0, 1.0,
            1.0, 1.0,
        ], 2);

        cube.type = "Cube";
        return cube;
    }

    static makeHexagonGeometry() {
        let vBuff = new Float32Array(7 * 2 * 3);
        let stepAngle = Math.PI / 3;
        let R = 1;
        // bottom vertex
        vBuff[0] = vBuff[1] = vBuff[2] = 0;
        // circle vertices
        let off = 3;
        for (let j = 0; j < 6; ++j) {
            let angle = j * stepAngle;
            let x = R * Math.cos(angle);
            let y = R * Math.sin(angle);
            let z = 0;
            vBuff[off] = x;
            vBuff[off + 1] = y;
            vBuff[off + 2] = z;
            off += 3;
        }
        // z depth vertices
        let hexHeight = 1;
        let ro = 0;
        for (let j = 0; j < 7; ++j) {
            vBuff[ro + 21] = vBuff[ro];
            vBuff[ro + 22] = vBuff[ro + 1];
            vBuff[ro + 23] = vBuff[ro + 2] + hexHeight;
            ro += 3;
        }

        let protoIdcs = [0,1,2, 0,2,3, 0,3,4, 0,4,5, 0,5,6, 0,6,1];
        let protoIdcs2 = [2,1,0,  3,2,0,  4,3, 0,   5,4,0,  6, 5, 0,  1, 6, 0];
        let sideIdcs = [8,1,2,2,9,8,  9,2,3,3,10,9,  10,3,4,4,11,10,
                        11,4,5,5,12,11,  5,6,13,5,13,12, 13,6,1,1,8,13 ];
        let idxBuffSize = protoIdcs.length * 2 + sideIdcs.length;
        let idxBuff = new Uint32Array(idxBuffSize);
        let b = 0;
        for (let c = 0; c < protoIdcs.length; c++) {
            idxBuff[b++] = protoIdcs2[c];
        }
        for (let c = 0; c < protoIdcs.length; c++) {
            idxBuff[b++] = protoIdcs[c] + 7;
        }
        for (let c = 0; c < sideIdcs.length; c++) {
            idxBuff[b++] = sideIdcs[c];
        }

        let hex = new Geometry();
		hex.vertices = Float32Attribute(vBuff,3);
		hex.indices = Uint32Attribute(idxBuff,1);
        hex.computeVertexNormals();
        // AMT do I need to set uv attributes ???

        hex.type = "Cube";// "Hexagon";
        return hex;
    }
}
