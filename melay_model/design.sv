// Code your design here
module elevator(
  input [3:0] req, 
  output reg [1:0] currentfloor,
  input clk,open,rst,close,floor_sensor,
  output reg motorup,motordown,opening,closing,
  input obstacle,overload);
  
  parameter idle=0;
  parameter movingup=1;
  parameter movingdown=2;
  parameter door=3;
  
 reg [1:0]state,next_state;
  reg [3:0] pending_reqs;
  reg door_is_closing;
  
  
  always@(*)
    begin
      motorup=0;
      motordown=0;
      opening=0;
      closing=0;
      next_state=state;
      
      if(overload)
        begin
          next_state=door;
          if(!open)
            opening=1;
        end
      else
        case(state)
          idle:begin
            if(req_here)
              next_state=door;
            else if(req_above)
              begin
                next_state=movingup;
                motorup=1;
              end
            else if(req_below)
              begin
                next_state=movingdown;
                motordown=1;
              end
          end
          
          movingup:begin
            if(req_here)
              next_state=door;
            else if(req_above)
              begin
                next_state=movingup;
                motorup=1;
              end
            else
              next_state=idle;
          end
          
          movingdown:begin
            if(req_here)
              next_state=door;
            else if(req_below)
              begin
                next_state=movingdown;
                motordown=1;
              end
            else
              next_state=idle;
          end
          
          door:begin
            if (door_is_closing) begin
              opening = 0;
              closing = 1;
              if (close)
                next_state = idle; // Door fully closed, safe to move
              else
                next_state = door;
            end else begin
              opening = 1;
              closing = 0;
              next_state = door;
            end
          end
          
          default:next_state=idle;
        endcase
    end
  
  always @(posedge clk)
    if(rst)
      begin
        state<=idle;
        currentfloor<=0;
        pending_reqs<=4'b0000;
        door_is_closing<=0;
      end
     else
       begin
         state<=next_state;
         
         pending_reqs <= pending_reqs | req;
         
         if(state == door)
           pending_reqs[currentfloor] <= 1'b0;
           
         if(floor_sensor)
           begin
             if(motorup)
               currentfloor<=currentfloor+1;
             else if(motordown)
               currentfloor<=currentfloor-1;
           end
           
         // Door direction control
         if (state != door)
           door_is_closing <= 0;
         else if (obstacle)
           door_is_closing <= 0; // Reopen instantly on obstacle
         else if (open)
           door_is_closing <= 1; // Door reached fully open, start closing
       end
  
      // Helper logic to check direction of pending requests
  wire req_above = (currentfloor == 0 && (pending_reqs[3] | pending_reqs[2] | pending_reqs[1])) |
                   (currentfloor == 1 && (pending_reqs[3] | pending_reqs[2])) |
                   (currentfloor == 2 && (pending_reqs[3]));

  wire req_below = (currentfloor == 3 && (pending_reqs[2] | pending_reqs[1] | pending_reqs[0])) |
                   (currentfloor == 2 && (pending_reqs[1] | pending_reqs[0])) |
                   (currentfloor == 1 && (pending_reqs[0]));
                   
  wire req_here  = pending_reqs[currentfloor];

  
            endmodule
