/* eslint-disable @typescript-eslint/no-non-null-assertion */
import {random} from 'remotion';
import {useMemo} from 'react';
import {useVideoConfig} from 'remotion';
import {useRef} from 'react';
import {useFrame} from '@react-three/fiber';
import {Mesh, ShaderMaterial, Vector2, VideoTexture} from 'three';
import {AcidShader} from './shaders/acid';
import {AsciiShader} from './shaders/ascii';
import {BillboardShader} from './shaders/billboard';
import {ColorBlockShader} from './shaders/colorblock';
import {ComicShader} from './shaders/comic';
import {DistortShader} from './shaders/distort';
import {DotMatrixShader} from './shaders/dotmatrix';
import {GlassicShader} from './shaders/glassic';
import {GlitchShader} from './shaders/glitch';
import {GridShader} from './shaders/grid';
import {KaleidoscopeShader} from './shaders/kaleidoscope';
import {MacysShader} from './shaders/macys';
import {PixelateShader} from './shaders/pixelate';
import {RainShader} from './shaders/rain';
import {CrossHatchShader} from './shaders/crosshatch';
import {SketchShader} from './shaders/sketch';

const Graphics: React.FC<{index: number; texture: VideoTexture | null}> = ({
	index,
	texture,
}) => {
	const geometry = useRef(null!);
	const mesh = useRef<Mesh>(null!);

	const {width, height} = useVideoConfig();

	const shaders = [
		AcidShader,
		AsciiShader,
		BillboardShader,
		ColorBlockShader,
		ComicShader,
		CrossHatchShader,
		DistortShader,
		DotMatrixShader,
		GlassicShader,
		GlitchShader,
		GridShader,
		KaleidoscopeShader,
		MacysShader,
		PixelateShader,
		RainShader,
		SketchShader,
	];

	const shader = shaders[Math.floor(random(index) * shaders.length)];

	const shaderUniforms = shader.uniforms;
	shaderUniforms.u_resolution.value = new Vector2(width, height);
	shaderUniforms.u_texture.value = texture;

	const {fragmentShader} = shader;

	const uniforms = useMemo(() => shaderUniforms, [shaderUniforms]);

	const materialConfig = {uniforms, fragmentShader};
	if (shader.vertexShader) {
		materialConfig.vertexShader = shader.vertexShader;
	}

	const shaderMaterial = new ShaderMaterial(materialConfig);

	useFrame((state, delta) => {
		if (mesh.current && mesh.current.material.uniforms.u_time) {
			if (mesh.current.material.uniforms.u_time) {
				mesh.current.material.uniforms.u_time.value = delta;
			}
		}
	});

	return (
		<mesh ref={mesh} material={shaderMaterial}>
			<boxGeometry ref={geometry} args={[1280, 720, 100]} />
		</mesh>
	);
};

export default Graphics;
