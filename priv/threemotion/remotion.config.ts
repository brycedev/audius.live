import {Config} from 'remotion';
import {CliConfig} from '@remotion/cli/config'

Config.setImageFormat('jpeg');
Config.setChromiumOpenGlRenderer('angle');
CliConfig.setChromiumOpenGlRenderer('angle');
Config.setMaxTimelineTracks(100);
