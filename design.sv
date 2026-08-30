// Code your design here
module elevator(
  input [3:0] req, 
  input clk, open, rst, close, floor_sensor, obstacle, overload,
  output reg [1:0] currentfloor,
  output motorup, motordown, opening, closing
);

  // MOORE Machine States (5 states instead of 4)
  parameter IDLE         = 0;
  parameter MOVING_UP    = 1;
  parameter MOVING_DOWN  = 2;
  parameter DOOR_OPENING = 3;
  parameter DOOR_CLOSING = 4;
  
  reg [2:0] state, next_state;
  reg [3:0] pending_reqs;
  
  // MOORE OUTPUTS: Strictly dependent on current state ONLY
  assign motorup   = (state == MOVING_UP);
  assign motordown = (state == MOVING_DOWN);
  assign opening   = (state == DOOR_OPENING);
  assign closing   = (state == DOOR_CLOSING);
  
  // Helper logic for the SCAN algorithm
  wire req_above = (currentfloor == 0 && (pending_reqs[3] | pending_reqs[2] | pending_reqs[1])) |
                   (currentfloor == 1 && (pending_reqs[3] | pending_reqs[2])) |
                   (currentfloor == 2 && (pending_reqs[3]));

  wire req_below = (currentfloor == 3 && (pending_reqs[2] | pending_reqs[1] | pending_reqs[0])) |
                   (currentfloor == 2 && (pending_reqs[1] | pending_reqs[0])) |
                   (currentfloor == 1 && (pending_reqs[0]));
                   
  wire req_here  = pending_reqs[currentfloor];

  // Sequential Logic: State Update & Memory
  always @(posedge clk) begin
    if(rst) begin
      state <= IDLE;
      currentfloor <= 0;
      pending_reqs <= 4'b0000;
    end else begin
      state <= next_state;
      
      // Latch new requests
      pending_reqs <= pending_reqs | req;
      
      // Clear request immediately when doors start opening
      if(state == DOOR_OPENING)
        pending_reqs[currentfloor] <= 1'b0;
        
      // Update floor based on current state
      if(floor_sensor) begin
        if(state == MOVING_UP)        currentfloor <= currentfloor + 1;
        else if(state == MOVING_DOWN) currentfloor <= currentfloor - 1;
      end
    end
  end
  
  always @(*) begin
    next_state = state; 
    
    case(state)
      IDLE: begin
        if(overload || req_here) next_state = DOOR_OPENING;
        else if(req_above)       next_state = MOVING_UP;
        else if(req_below)       next_state = MOVING_DOWN;
      end
      
      MOVING_UP: begin
        if(req_here)             next_state = DOOR_OPENING;
        else if(!req_above)      next_state = IDLE;
      end
      
      MOVING_DOWN: begin
        if(req_here)             next_state = DOOR_OPENING;
        else if(!req_below)      next_state = IDLE;
      end
      
      DOOR_OPENING: begin
        if(open) begin 
          if(overload) next_state = DOOR_OPENING; // Hold open
          else         next_state = DOOR_CLOSING; // Door fully opn
        end
      end
      
      DOOR_CLOSING: begin
        if(obstacle || overload) next_state = DOOR_OPENING; // Reopen
        else if(close)           next_state = IDLE;         // Door fully closed
      end
      
      default: next_state = IDLE;
    endcase
  end
endmodule