module weights_rom(
    input [1:0] layer_number,
    output reg [279:0] weights_and_biases,
    output reg [3:0] weight_matrix_rows,
    output reg [3:0] weight_matrix_columns
);

always @(*)
begin
    case(layer_number)
    2'd0:begin //layer one
        // Format: {bias3, bias2, bias1, w3_3, w3_2, w3_1, w2_3, w2_2, w2_1, w1_3, w1_2, w1_1}
        weights_and_biases = {
            -10'sd122, -10'sd183, -10'sd254,        // Biases (reverse order for easier unpacking)
            -10'sd187, 10'sd309, 10'sd180,               // Weights for neuron 3
            10'sd175, 10'sd226, 10'sd238,              // Weights for neuron 2
            10'sd117, 10'sd70, 10'sd39               // Weights for neuron 1
        };
        weight_matrix_rows = 4'd3;
        weight_matrix_columns = 4'd3;
    end

    2'd1:begin //layer two
        weights_and_biases = {
            // Biases in reversed order
            10'sd0,
            -10'sd109,
            10'sd122,
            10'sd0,
            -10'sd166,
            10'sd0,

            // Weights in reversed neuron order
            -10'sd108, -10'sd40,  -10'sd142, -10'sd163, 10'sd122,  -10'sd34,
            -10'sd70,  10'sd189,  10'sd7, -10'sd152, 10'sd103,  -10'sd56,
            -10'sd144, 10'sd105,  10'sd148, -10'sd32,  10'sd148,  -10'sd142
        };
        weight_matrix_rows = 4'd3;
        weight_matrix_columns = 4'd6;
    end

    2'd2:begin //layer three
        weights_and_biases = {
            // Biases in reversed order
            -10'sd13,     // Bias 4
            -10'sd51,     // Bias 3
            10'sd0,      // Bias 2
            -10'sd147,    // Bias 1

            // Weights in reversed neuron order
            10'sd169,  10'sd157,  10'sd43,   10'sd56,
            -10'sd135, -10'sd160, -10'sd64,   10'sd268,
            -10'sd52,   10'sd82,  -10'sd152, -10'sd81,
            10'sd83,  -10'sd152,  10'sd3,   -10'sd67,
            10'sd128,  10'sd153, -10'sd7,    10'sd254,
            -10'sd62,  -10'sd174, 10'sd41,   -10'sd60
        };
        weight_matrix_rows = 4'd6;
        weight_matrix_columns = 4'd4;
    end

    2'd3:begin //layer four (final)
        weights_and_biases = {
                -10'sd82, //Bias
                -10'sd220, 10'sd8, 10'sd273, 10'sd121
        };
        weight_matrix_rows = 4'd4;
        weight_matrix_columns = 4'd1;
    end
    endcase

end
endmodule

module weightBiasBlock(
    input clk,
    input [279:0] weights_and_biases,
    input [3:0] weight_matrix_rows,
    input [3:0] weight_matrix_columns,
    output reg [279:0] WB_register,
    output reg [3:0] rows,
    output reg [3:0] cols
);

always @(posedge clk)begin
    WB_register <= weights_and_biases;
    rows <= weight_matrix_rows;
    cols <= weight_matrix_columns;
end
endmodule

module input_register(
    input clk,
    input [383:0] data_in, //64 bytes per chunk of data for storing multiplication results accurately
    output reg [383:0] data_out
);
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule

module alu_result_register(
    input clk,
    input [383:0] alu_result,
    output reg [383:0] alu_data
);
    always @(posedge clk) begin
        alu_data <= alu_result;
    end
endmodule


module muxer(
    input [383:0] input_data,
    input [383:0] ALU_feedback,
    output reg [383:0] output_data,
    input select_line
);

always @(*)begin
    case(select_line)
        0:begin
            output_data = input_data;
        end
        1:begin
            output_data = ALU_feedback;
        end
    endcase
end
endmodule

module ALU(
    input clk,
    input enable,
    input [279:0] WB_register,
    input [3:0] rows,
    input [3:0] cols,
    input [383:0] input_data,
    output reg [383:0] output_data
);

integer i, j;
reg signed [31:0] res = 0;
reg signed [63:0] input_element;
reg signed [63:0] weight;
reg signed [63:0] temp64;
reg signed [9:0] temp10;
reg signed [63:0] result_array [0:5];

always @(posedge clk)begin
    if (enable) begin
    for (j = 0; j < cols; j = j + 1) begin
        res = 0;
        for (i = 0; i < rows; i = i + 1) begin
            //rows - 1 - i because we need to access the leftmost element first, not the rightmost element
            temp64 = ((input_data >> (64*(rows - 1 - i))) & 64'hFFFFFFFFFFFFFFFF);
            input_element = $signed(temp64);
            temp10 = ((WB_register >> (10*(j+cols*i))) & 10'h3FF);
            weight = {{54{temp10[9]}}, temp10};
            res = res + input_element*weight;
        end
        temp10 = ((WB_register >> (10*(j+cols*rows))) & 10'h3FF);
        weight = {{54{temp10[9]}}, temp10};
        res = res + weight;

        result_array[j] = res;
    end

    output_data = 384'd0;
    for (j = 0; j < cols; j = j + 1)begin
        output_data = output_data | (result_array[j] << (64*(cols-1-j)));
    end
    end
end
endmodule