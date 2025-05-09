<h1 >Pipelined Neural Network Inference Processor (Verilog)</h1>

This repository contains the source code for a hardware-implemented neural network inference engine, built using Verilog. The project emulates the feedforward behavior of a fully connected neural network using a pipelined architecture. It processes input data through a series of weight and bias computations, using fixed weights stored in a ROM.
(This project was built as part of a broader study into combining neural network computation with digital design. The model was pre-trained using software (Python) and weights were exported manually for use in hardware.)

<h3 >About the neural network processor:</h3>
Implements a 4-layered dense network
Modular and pipelined design
Uses signed weights and biases

<h3 >Processor design:</h3>

![PipelineDiag_beta](https://github.com/user-attachments/assets/fa32cfc7-2f3c-4e1e-ba12-625056dca277)

<h3 >Network Architecture:</h3 >

The neural network consists of 4 layers, each with hardcoded weights and biases:

    Layer|	Inputs|	Outputs| Description
    1	 |  3	  | 3	   | Dense + Bias
    2    |	3	  | 6	   | Dense + Bias
    3	 |  6	  | 4	   | Dense + Bias
    4	 |  4	  | 1	   | Final output neuron

All weights and biases are encoded as signed 10-bit fixed-point values and retrieved based on the current layer_number.

<h3 >Module Overview:</h3>

    weights_rom
    Stores hardcoded weights and biases for each layer.

    weightBiasBlock
    Loads the ROM outputs into registers on clock edges.

    input_register
    Buffers the input vector for each layer (e.g., input or previous layer output).

    muxer
    Selects between external input data and ALU feedback (for intermediate layer chaining).

    ALU
    Performs dot-product between weights and inputs, adds biases, and outputs result.

    alu_result_register
    Captures the ALU result for possible feedback into the next layer.

<h3 >Testbench:</h3>

The nn_hdl_testbench simulates a full forward pass through all four layers using a sample input:

input_data = {64'sd10, -64'sd5, 64'sd40}; // Example 3-element input vector

Clock cycles are used to sequence through the layers with the MUX switching between original input and ALU feedback.

<h3 >How It Works:</h3>

    Load input vector into input_register

    Set layer_no to 0 to fetch Layer 1 weights and biases

    ALU performs:
    output = (input ⋅ weights) + bias

    Output is passed as input to the next layer using MUX feedback

    Repeat steps for all 4 layers

    Final output is available after all stages

<h3 >Simulation Output</h3>

Simulation waveform can be viewed by inspecting tinynn_results_real.vcd in any VCD viewer (e.g., GTKWave). The testbench fully verifies the functional correctness of all pipeline stages.

<h3 >Running the Simulation:</h3>

    iverilog -o nn_test nn_hdl_testbench.v *.v
    vvp nn_test
    gtkwave tinynn_results_real.vcd

<h3 >Future Extensions:</h3>
Expand ROM to support more layers/neuron sizes
<br />Add softmax or classification output layer
