extern crate rustfft;

use aubio::{OnsetMode, Tempo};
use hound::WavReader;
use rustler::Error as RustlerError;

#[rustler::nif]
pub fn detect_beats(path: &str) -> Result<f32, RustlerError> {
    match priv_detect_beats(path) {
        Ok(seconds_per_beat) => Ok(seconds_per_beat),
        Err(_err) => Err(RustlerError::Atom("error")),
    }
}

fn priv_detect_beats(path: &str) -> Result<f32, String> {
    let mut reader = WavReader::open(path).unwrap();
    let sample_rate = reader.spec().sample_rate;
    println!("Sample rate: {}", sample_rate);
    let buffer_size = 1024;
    let num_channels = reader.spec().channels as usize;

    let mut tempo = Tempo::new(OnsetMode::Energy, buffer_size, buffer_size, sample_rate).unwrap();
    let mut buffer = vec![0.0; buffer_size as usize * num_channels];

    for sample in reader.samples::<i16>() {
        let sample = sample.unwrap() as f32 / i16::MAX as f32;
        buffer.push(sample);
        // if buffer.len() >= buffer_size as usize * num_channels {
        //     // Detect the tempo of the audio data in the buffer
        // }
    }

    let bpm = tempo.do_result(&buffer).unwrap();
    println!("Tempo: {:.2} BPM", bpm);
    buffer.clear();
    // let seconds_per_beat = 0.0;

    // fft.process(&mut buffer);

    // let mut seconds_per_beat = 0.0;

    // let tempo_result = tempo.do_result(&buffer[..num_samples]);
    // let seconds_per_beat = 60.0 / tempo_result.unwrap();

    // println!("BPM: {}", tempo_result.unwrap());

    // if tempo_result.tempo > 0.0 {
    //     seconds_per_beat = 60.0 / tempo_result.tempo;
    //     println!("BPM: {}", tempo_result.tempo);
    // }
    // loop {
    //     match reader.into_samples() {
    //         Ok(n) => {
    //             if n == 0 {
    //                 break;
    //             }
    //             let tempo_result = tempo.do_tempo(&buffer[..n]);
    //             if tempo_result.tempo > 0.0 {
    //                 seconds_per_beat = 60.0 / tempo_result.tempo;
    //                 println!("BPM: {}", tempo_result.tempo);
    //             }
    //         }
    //         Err(_) => {
    //             break;
    //         }
    //     }
    // }
    Ok(1.0)
}

rustler::init!("Elixir.Rust", [detect_beats]);
