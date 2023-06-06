import {staticFile, useCurrentFrame} from 'remotion';
import {Audio} from 'remotion';
import {useVideoConfig} from 'remotion';
import React from 'react';
import BaseVisualiser from './visualiser/base';
import {Series} from 'remotion';
import {useAudioData, visualizeAudio} from '@remotion/media-utils';

const audio = staticFile('audio.mp3');

export const Scene: React.FC = () => {
	const frame = useCurrentFrame();
	const {durationInFrames, fps} = useVideoConfig();
	const interval = Math.ceil(durationInFrames / 19);
	const audioData = useAudioData(audio);

	if (!audioData) {
		return null;
	}

	const visualisation = visualizeAudio({
		fps,
		frame,
		audioData,
		numberOfSamples: 32,
	});

	return (
		<>
			<Series>
				{Array.from({length: 19}).map((_, i) => {
					return (
						<Series.Sequence durationInFrames={interval}>
							<BaseVisualiser index={i} />
						</Series.Sequence>
					);
				})}
			</Series>
			<Audio src={audio} />
		</>
	);
};
