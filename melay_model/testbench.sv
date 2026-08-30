module tb_elevator;

  // Inputs
  reg [3:0] req;
  reg clk, rst, open, close, floor_sensor;
  reg obstacle, overload;

  // Outputs
  wire [1:0] currentfloor;
  wire motorup, motordown, opening, closing;

  // Instantiate the Unit Under Test (UUT)
  elevator uut (
    .req(req), 
    .currentfloor(currentfloor), 
    .clk(clk), 
    .open(open), 
    .rst(rst), 
    .close(close), 
    .floor_sensor(floor_sensor), 
    .motorup(motorup), 
    .motordown(motordown), 
    .opening(opening), 
    .closing(closing), 
    .obstacle(obstacle), 
    .overload(overload)
  );

  // Clock generation (10 time units period)
  always #5 clk = ~clk;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_elevator);

    // 1. Initialize Inputs
    clk = 0; rst = 1; 
    req = 4'b0000;
    open = 0; close = 1; // Door starts physically closed
    floor_sensor = 0; obstacle = 0; overload = 0;

    // Release reset
    #15 rst = 0;

    // -----------------------------------------------------------
    // TEST 1: Multiple Requests (Sweep UP)
    // -----------------------------------------------------------
    $display("--- Test 1: Multiple Requests (Floors 1 and 3) ---");
    #10 req = 4'b1010; // Request Floor 1 and Floor 3 simultaneously
    #10 req = 4'b0000; // Release buttons 
    
    // Arrive at floor 1
    #20 floor_sensor = 1; #10 floor_sensor = 0; 
    
    // NEW Realistic Door Sequence at Floor 1
    #20 open = 1; close = 0; // Limit switch: Door reached fully open
    #20 open = 0; close = 1; // Limit switch: Door reached fully closed (FSM goes idle)

    // Pass floor 2
    #20 floor_sensor = 1; #10 floor_sensor = 0;

    // Arrive at floor 3
    #20 floor_sensor = 1; #10 floor_sensor = 0;

    // NEW Realistic Door Sequence at Floor 3
    #20 open = 1; close = 0; 
    #20 open = 0; close = 1; 

    // -----------------------------------------------------------
    // TEST 2: Move DOWN to Floor 0
    // -----------------------------------------------------------
    $display("--- Test 2: Moving DOWN to Floor 0 ---");
    #10 req = 4'b0001; // Request Floor 0
    #10 req = 4'b0000;
    
    #20 floor_sensor = 1; #10 floor_sensor = 0; // Pass floor 2
    #20 floor_sensor = 1; #10 floor_sensor = 0; // Pass floor 1
    #20 floor_sensor = 1; #10 floor_sensor = 0; // Arrive floor 0

    // Realistic Door Sequence at Floor 0
    #20 open = 1; close = 0; 
    #20 open = 0; close = 1; 

    // -----------------------------------------------------------
    // TEST 3: Obstacle Detection
    // -----------------------------------------------------------
    $display("--- Test 3: Obstacle Detection ---");
    #10 req = 4'b0100; // Request Floor 2
    #10 req = 4'b0000;
    
    #20 floor_sensor = 1; #10 floor_sensor = 0; // Pass floor 1
    #20 floor_sensor = 1; #10 floor_sensor = 0; // Arrive floor 2
    
    // Door sequence with an obstacle interrupting the close
    #20 open = 1; close = 0; // Door opens fully
    #10 obstacle = 1;        // Someone blocks the laser sensor
    #20 obstacle = 0;        // Obstacle clears
    #20 open = 0; close = 1; // Door finally allowed to close fully

    // -----------------------------------------------------------
    // TEST 4: Overload condition
    // -----------------------------------------------------------
    $display("--- Test 4: Overload ---");
    #20 overload = 1; // Trigger weight overload
    #40 overload = 0; // Passenger steps out
    
    // Close the door after overload clears
    #20 open = 1; close = 0; 
    #20 open = 0; close = 1; 

    #40 $display("--- Simulation Complete! ---");
    $finish;
  end

  // Monitor to print outputs
  initial begin
    $monitor("Time=%3t | Req=%b CurrFlr=%0d | Motor(U=%b,D=%b) | Door(Opn=%b,Cls=%b) | State=%0d | Mem=%b", 
             $time, req, currentfloor, motorup, motordown, opening, closing, uut.state, uut.pending_reqs);
  end

endmodule
