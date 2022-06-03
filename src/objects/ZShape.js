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
        if (material === null) {
            material = new ZShapeBasicMaterial();
        }

        // MT for Sebastien -- what would be the best way to clone material?
        // ZShapeBasicMaterial.clone_for_outline() seems OK (but one needs to 
        // take care with uniform / texture / instanceData updates).

        // let pmat = Object.assign(new ZShapeBasicMaterial(), material);
        // pmat.addSBFlag('PICK_MODE_UINT'); // should get it from PickingShaderMaterial
        let pmat = undefined;
        // let omat = Object.assign(new ZShapeBasicMaterial(), material);
        // omat.addSBFlag('OUTLINE');
        let omat = material.clone_for_outline();

        //SUPER
        super(geometry, material, pmat, omat);
        this.type = "ZShape";


        if (geometry === null) {
            /*
            let xy0 = new Vector2(-0.5, 0.5);
            let xy1 = new Vector2(0.5, -0.5);
            geometry = Quad.makeGeometry(xy0, xy1, false, true, false, false);
            */
            geometry = this.makeCubeGeometry();
           console.log("zshape cube geometry ", geometry);
           this._geometry = geometry;
        }
    }

    makeCubeGeometry() {
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

}
