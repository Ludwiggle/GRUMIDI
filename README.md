# GRUMIDI

A GRU<sup>1</sup>-based RNN<sup>2</sup> for rhythmic pattern generation.
The RNN model is a
[char-rnn](http://karpathy.github.io/2015/05/21/rnn-effectiveness/)
trained on a sequence of
[unit vectors](https://en.wikipedia.org/wiki/Unit_vector)
representing the input MIDI file.


## Prerequisite
[MathKernel](https://www.wolfram.com/cdf-player) and
[Wolframscript](https://www.wolfram.com/wolframscript)

Run `$ wolframscript -configure` and set the variable `WOLFRAMSCRIPT_KERNELPATH` to your local `MathKernel` address


## Usage

1. Run `$ wolframscript -f encodeAndTrain.wl`

    Type the input filename<sup>5</sup> `*.mid`



The trained net and decoding parameters are saved in `data/`.


2. Run `$ wolframscript -f generateAndDecode.wl`

    Generated `*.mid` is saved in `data/`.



## Discussion

In general, a MIDI file is not defined on a time-grid; the beginning and the end of a MIDI event can be machine-precision digits.
The first script will take care of time-quantization by fitting the MIDI events on a time-grid at a resolution equal to the minimum time-interval between two events found in the input MIDI file.
The generated MIDI inherits this time-quantization.

The dimension of the [unit vectors](http://reference.wolfram.com/language/ref/UnitVector.html) is equal to the number of different "notes", e.g. the chromatic scale would be encoded with 12-dimensional unit vectors. Polyphony is encoded by vector addition of simultaneous events.

Inspired by [LSTMetallica](https://github.com/keunwoochoi/LSTMetallica), the encoded MIDI input


ciao ciao



<sup>1</sup>Gated Recurrent Unit

<sup>2</sup>Recurrent Neural Network

<sup>3</sup>Musical Instrument Digital Interface

<sup>4</sup>Full address or local address.
