module nn_hdl_testbench;

reg clk;
reg enable;
reg [1:0] layer_no;
wire [279:0] weights_and_biases; 
wire [3:0] weight_matrix_rows;
wire [3:0] weight_matrix_columns;
reg [383:0] input_data;
reg select_line;

wire [383:0] input_fromReg;

wire [383:0] output_data;
wire [3:0] rows;
wire [3:0] cols;
wire [279:0] WB_register;
wire [383:0] mux_out;

initial begin
    $dumpfile("tinynn_results_real.vcd"); // VCD output file
    $dumpvars(0, nn_hdl_testbench);
end

initial clk = 0;
always #5 clk = ~clk; 


weights_rom Weights(
    .layer_number(layer_no),
    .weights_and_biases(weights_and_biases),
    .weight_matrix_rows(weight_matrix_rows),
    .weight_matrix_columns(weight_matrix_columns)
);

weightBiasBlock WB_Block (
    .clk(clk),
    .weights_and_biases(weights_and_biases),
    .weight_matrix_rows(weight_matrix_rows),
    .weight_matrix_columns(weight_matrix_columns),
    .WB_register(WB_register),
    .rows(rows),
    .cols(cols)
);

ALU alu_inst (
    .clk(clk),
    .enable(enable),
    .WB_register(WB_register),
    .rows(rows),
    .cols(cols),
    .input_data(mux_out),
    .output_data(output_data)
);

input_register input_reg_data(
    .clk(clk),
    .data_in(input_data),
    .data_out(input_fromReg)
);

muxer multiplex(
    .input_data(input_fromReg),
    .select_line(select_line),
    .ALU_feedback(output_data),
    .output_data(mux_out)
);

initial begin
    layer_no = 2'd0;
    select_line = 1'd0;
    input_data = {64'sd10, -64'sd5, 64'sd40}; //from the dataset
    enable = 0;
    @(posedge clk);
    enable = 1;
    layer_no = 2'd1; //pre-selecting to fetch the weights in time
    @(posedge clk);
    select_line = 1'd1;
    layer_no = 2'd2;
    @(posedge clk);
    layer_no = 2'd3;
    @(posedge clk);
    
    @(posedge clk);
    @(posedge clk);
    
    $finish;

end
endmodule