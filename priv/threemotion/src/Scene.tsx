import {staticFile} from 'remotion';
import {Audio} from 'remotion';
import React from 'react';
import BaseVisualiser from './visualiser/base';
import {Series} from 'remotion';
import beatData from '../public/beats.json';

const audio = staticFile('audio.mp3');

export const Scene: React.FC = () => {
	return (
		<>
			<Series>
				{Array.from({length: beatData.length}).map((_, i) => {
					return (
						<Series.Sequence durationInFrames={beatData[i]}>
							<BaseVisualiser key={i} index={i} />
						</Series.Sequence>
					);
				})}
			</Series>
			<Audio src={audio} />
		</>
	);
};
