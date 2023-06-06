import {continueRender} from 'remotion';
import {useEffect, useState} from 'react';
import {delayRender, staticFile} from 'remotion';
import {Composition} from 'remotion';
import {Scene} from './Scene';
import {getAudioDurationInSeconds} from '@remotion/media-utils';

export const RemotionRoot: React.FC = () => {
	const [handle] = useState(() => delayRender());
	const [duration, setDuration] = useState(1);

	useEffect(() => {
		getAudioDurationInSeconds(staticFile('audio.mp3')).then(
			(durationInSeconds) => {
				setDuration(Math.round(durationInSeconds * 24));
				continueRender(handle);
			}
		);
	}, [handle]);

	return (
		<>
			<Composition
				id="Scene"
				component={Scene}
				durationInFrames={duration}
				fps={24}
				width={1280}
				height={720}
			/>
		</>
	);
};
