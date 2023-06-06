import {Video, staticFile} from 'remotion';
import {useVideoConfig} from 'remotion';
import {useRef} from 'react';
import {ThreeCanvas, useVideoTexture} from '@remotion/three';
import Graphics from './graphics';

const BaseVisualiser = ({index = 0}) => {
	const video = useRef<HTMLVideoElement>(null);
	const {width, height} = useVideoConfig();
	const texture = useVideoTexture(video);
	const gif = staticFile(`gifs/${index}.mp4`);

	return (
		<>
			<Video ref={video} loop src={gif} style={{display: 'none'}} />
			<ThreeCanvas
				orthographic={false}
				width={width}
				height={height}
				style={{
					backgroundColor: 'black',
				}}
				camera={{fov: 75, position: [0, 0, 420]}}
			>
				<Graphics index={index} texture={texture} />
			</ThreeCanvas>
		</>
	);
};

export default BaseVisualiser;
