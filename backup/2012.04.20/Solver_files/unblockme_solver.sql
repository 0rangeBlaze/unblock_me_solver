clear screen
set timing on
set serveroutput on size 30000

create or replace package unblockme is
  procedure dosolve(a_str varchar2);
  procedure generate_svg;
end;
/
show err

create or replace package body unblockme as

  TYPE BlockType IS RECORD (
    x NUMBER(1),
    y NUMBER(1),
    length number(1),
    orientation varchar2(1),
    marker varchar2(1)
  );
  
  type blocksArrayType IS TABLE OF BlockType INDEX BY binary_integer;
  
  TYPE StepType IS RECORD (
    key varchar2(36),
    level number(10),
    parent_id number,
    moved varchar2(1),
    position blocksArrayType
  );
  
  
  type gridcellarray IS TABLE OF varchar2(1) INDEX BY binary_integer;
  type boardtype IS TABLE OF gridcellarray INDEX BY binary_integer;
  type stepstype IS TABLE OF steptype index by binary_integer;
  
  blocks blocksArrayType;
  steps stepstype;
  id number := 0;
  lvl number := 0;
  v_str varchar2(36);
  print_mode number := 2;


-- svg constants

  cell_width number(10) := 50;
  main_frame_width number := 6;
  block_frame_width number := 3;
  xoffset number := 460;
  yoffset number := 50;
  board_corner_radius number := 2;
  block_corner_radius number := 8;
  
  board_color varchar2(50) := 'RGB(103,73,30)';
  main_frame_color varchar2(50) := 'RGB(168,123,45)';
  block_frame_color varchar2(50) := 'Sienna';
  block_color_wood varchar2(50) := 'RGB(220,141,61)';
  block_color_red varchar2(50) := 'RGB(194,33,2)';
  svg_ident varchar2(50) := '  ';
  
-- svg constants end

  procedure printstring(a_str varchar2) is
  begin
    for i in 0..5 loop
      dbms_output.put_line(replace(substr(a_str, i*6 + 1 , 6),'0','.'));
    end loop;
    dbms_output.put_line('  ');
  end;

  function boardtostring(a_board  boardtype) return varchar2 is
  v_str varchar2(36);
  begin
    for i in 0..5 loop
      for j in 0..5 loop
        v_str := v_str || a_board(j)(i);
      end loop;    
    end loop;
  return(v_str);
  end;

  
  function boardfromblocks (a_position blocksArrayType) return boardtype is
    a_board boardtype;
    a_block blocktype;
  begin
    for i in 0..5 loop
      for j in 0..5 loop
        a_board(i)(j) := '0';
      end loop;    
    end loop;

    for c in 0..a_position.count - 1 loop
      a_block := a_position(c);
      if a_block.orientation = '-' then
        for i in 0..a_block.length - 1 loop
          a_board(a_block.x + i)(a_block.y) := a_block.marker;
        end loop;
      else
        for i in 0..a_block.length - 1 loop
          a_board(a_block.x)(a_block.y + i) := a_block.marker;
        end loop;    
      end if;
    end loop;
    
    return a_board;
  end;


  function blockstostring(a_position blocksarraytype) return varchar2 is
  begin
    return(boardtostring(boardfromblocks(a_position)));
  end;

/*  
  procedure registerblock (a_x number, a_y number, a_l number, a_O varchar2, a_m varchar2 default null) is
  id number;
  begin
    id := blocks.count;

    blocks(id).x := a_x;
    blocks(id).y := a_y;
    blocks(id).length := a_l;
    blocks(id).orientation := a_o;
    blocks(id).marker := nvl(a_m,CHR(ASCII('A') + id));
    addblock(board, blocks(id));
  end;
   
   
  procedure codedstringtoblocks(a_str varchar2) is
  v_x number;
  v_y number;
  v_o varchar2(1);
  v_l number;  
  v_m varchar2(1);
  v_str varchar2(150) := a_str;
  
  begin
    loop
      exit when length(v_str) = 0;
      v_x := substr(v_str,1,1);
      v_y := substr(v_str,2,1);
      v_o := substr(v_str,3,1);
      v_l := substr(v_str,4,1);
      if v_y = 2 and v_o = '|' then
        v_m := 'X';
      end if;  
      registerblock(v_x,v_y,v_l,v_o,v_m);
    end loop;
  end;      
*/
   

  function stringtoblocks(a_str varchar2) return blocksarraytype is
  
    v_filler varchar2(1) := '0';
    v_done varchar2(30) := ' ';
    v_m varchar2(1);
    blocks blocksarraytype;
    v_grid_size number := 6;
  
  begin
    for i in 1..v_grid_size * v_grid_size loop
      v_m := substr(a_str, i , 1);
      if v_m <> v_filler and instr(v_done, v_m) = 0 then
      
        blocks(id).x := mod((i - 1),v_grid_size);
        blocks(id).y := trunc((i - 1)/v_grid_size);
        blocks(id).length := v_grid_size * v_grid_size - length(replace(a_str,v_m,''));
        blocks(id).marker := v_m;

        if blocks(id).x < v_grid_size and substr(a_str, i + 1, 1) = blocks(id).marker then
          blocks(id).orientation := '-';
        elsif blocks(id).y < v_grid_size and substr(a_str, i + v_grid_size, 1) = blocks(id).marker then
          blocks(id).orientation := '|';
        else
          raise_application_error(-20000, 'Can not determine block orientation : block = ' || blocks(id).marker);
        end if;

        v_done := v_done || blocks(id).marker;
        id := id + 1;
      end if;
    end loop;
    
    return(blocks);
  end;   


  procedure printstep(a_id number) is
    position blocksArrayType := steps(a_id).position;
    block  blocktype;
    sep varchar2(1);
    id varchar2(3);
  begin
    dbms_output.put('steps[' || lvl || '] = [');
    lvl := lvl + 1;
    for i in 0..position.count - 1 loop
      block := position(i);
      if i = 0 then sep := ''; else sep := ','; end if;
      if block.orientation = '|' then id := 'V'; else id := 'H'; end if;
      if block.length = 2 then
        id := lower(id);
       end if ;
       
       if lower(block.marker) = 'x' then id := 'x'; end if;
       id := id || block.x || block.y;
         
      dbms_output.put(sep || '"'|| id ||'"');
    end loop;
    dbms_output.put_line('];');
  end;

 
  procedure solutionfound(id number) is
  begin
    if steps(id).parent_id is null then
   /* 
      dbms_output.put_line('solution at level : '||lvl);
      dbms_output.put_line('=======================================');
      printstring(steps(id).key);
   */
     printstep(id);
    else
      solutionfound(steps(id).parent_id);
    /*  
      dbms_output.put_line('moved : '||steps(id).moved);
      dbms_output.put_line('---------');
      printstring(steps(id).key);      
    */  
      printstep(id);
    end if;
  end;



  function move(a_position in out nocopy blocksArrayType, a_block_id number, a_coord number) return varchar2 is
    block blocktype := a_position(a_block_id);
    a_board boardtype := boardfromblocks(a_position);
    key varchar2(36);
  begin

    if block.orientation = '-' then
      if a_coord =  block.x then  return null; end if;

      for i in least(block.x, a_coord)..greatest(block.x, a_coord) + block.length - 1 loop
        if not a_board(i)(block.y) in ('0',block.marker) then return null; end if;  
      end loop;

      a_position(a_block_id).x := a_coord;
    else
      if a_coord =  block.y then  return null; end if;

      for i in least(block.y, a_coord)..greatest(block.y, a_coord) + block.length - 1 loop
        if not a_board(block.x)(i) in ('0',block.marker) then return null; end if;  
      end loop;

      a_position(a_block_id).y := a_coord;
    end if;

    key := blockstostring(a_position);
    for i in 0..steps.count - 1 loop
      if steps(i).key = key then
        return null;
      end if;
    end loop;
    
    return key;
    
  end;

  

  procedure solve is
    step steptype;
    id number;
    done boolean;
    position blocksarraytype;
    key varchar2(36);
    
  begin
  
    loop
      done := true;
--      dbms_output.put_line(lvl || ' ' ||steps.count);
      for c in 0..steps.count - 1 loop
        if steps(c).level = lvl then
          
          for i in 0..steps(c).position.count - 1 loop
            for j in 0..6 - steps(c).position(i).length loop
              position := steps(c).position;
              key := move(position,i,j);
              if key is not null then
                
                done := false;
                id := steps.count;
                steps(id).key := key;
                steps(id).parent_id := c;
                steps(id).moved := position(i).marker;
                steps(id).level := lvl + 1;
                steps(id).position := position;

                if substr(steps(id).key,17,2) = 'XX' then 
                  lvl:=0;
                  solutionfound(id);
                  return;
                end if;

              end if;
            end loop;
          end loop;      
        end if;
      end loop;
      
      lvl := lvl + 1;
      exit when done;
    end loop;

  end;

procedure dosolve (a_str varchar2) is
begin
  v_str := a_str;
  steps.delete;
  id := 0;
  lvl := 0;
  
  steps(0).key:= v_str;
  steps(0).level := 0;
  steps(0).parent_id := null;
  steps(0).position := stringtoblocks(v_str);

  solve;
end;


	procedure generate_block_svg(a_block blocktype) is
			
		blocks blocksarraytype;
		width number(10);
		height number(10);
		x number;
		y number;
		id varchar2(10);

    block  blocktype := a_block;
		
		block_color varchar2(50);
		
		
	begin
	
      if lower(block.orientation)  = 'h' and block.x + block.length > 6 then 
      return; end if;
      if lower(block.orientation)  = 'v' and block.y + block.length > 6 then return; end if;
      
			x := xoffset + block.x * cell_width + main_frame_width;
			y := yoffset + block.y * cell_width + main_frame_width;
			block_color := block_color_wood;
			if lower(a_block.marker) = 'x' then id := 'x'; else id := a_block.orientation; end if;
			
			
			if lower(block.orientation) = 'h' then
				width := block.length * cell_width;
				height:= cell_width;
				if lower(block.marker) = 'x' then block_color := block_color_red; end if;
				if block.length = 3 then id := 'H'; end if;
			else
				width := cell_width;
				height:= block.length * cell_width;
				if block.length = 3 then id := 'V'; end if;
			end if;

      id := id || block.x || block.y;
     
			dbms_output.put_line(svg_ident||'<rect id="'||id||'" x="'||x||'" y="'||y||'" rx="'||block_corner_radius||'" ry="'||block_corner_radius||'" width="'||width||'" height="'||height||'" style="visibility:hidden;fill:'||block_color||';stroke:'||block_frame_color||';stroke-width:'||block_frame_width||';opacity:1"/>');				

	end;

  procedure generate_svg is
    block blocktype;
    dim number;
  begin
    dim := (6 * cell_width + 2 * main_frame_width);
    dbms_output.put_line('<svg height="'||dim||'" xmlns="http://www.w3.org/2000/svg" version="1.1">');
		dbms_output.put_line(svg_ident||'<rect x="'||xoffset||'" y="'||yoffset||'" rx="'||board_corner_radius||'" ry="'||board_corner_radius||'" width="'||dim||'" height="'||dim||'" style="fill:'||board_color||';stroke:'||main_frame_color||';stroke-width:'||main_frame_width||';opacity:1"/>');

    
    for x in 0..5 loop
      for y in 0..5 loop
        block.x := x;
        block.y := y;
        
        block.length := 2;
        block.orientation := 'v';
        generate_block_svg(block);
        block.orientation := 'h';
        generate_block_svg(block);
        block.length := 3;
        block.orientation := 'V';
        generate_block_svg(block);
        block.orientation := 'H';
        
        generate_block_svg(block);        
      end loop;
    end loop;
    
    block.length := 2;
    block.y := 2;
    block.orientation := 'h';
    block.marker := 'x';

    for x in 0..4 loop
      block.x := x;
      generate_block_svg(block);
    end loop;
    
    dbms_output.put_line('</svg>');
  end;


END;
/
show err


spool result.log
declare
v_str varchar2(1000);
begin
--  dbms_hprof.start_profiling('DATA_PUMP_DIR', 'unblockme.trc');

--  v_str := 'ABBB0CA0DE0CXXDE0C00DFGG0HHFJ00IIIJ0';
--  v_str := 'AA0BC0DDDBC0XX0BE0F0GGE0F0IJJ0HHI000';
--  v_str := 'A0BBB0ACCDE0XXJDE0KKJGE0000GFF0IIHH0';

--  v_str := 'AAABCDEFFBCDEXXG00HHIGKK00IJJL00000L'; -- expert challenge 108
--  v_str := 'A0EFFHA0EGGHBXXI0HB00IKKCC0J00DDDJ00'; -- expert challenge 27
--  v_str := 'ABCCDDABE000XXE00KFFEJ0KGHHJ0KGIII00'; -- expert challenge 398
	v_str := 'A0BBCCA0DD0EXXH00E00HGGFIIHK0FJJJK00'; -- Spica 4926
  
  
  unblockme.generate_svg;
  unblockme.dosolve(v_str);

--  dbms_hprof.stop_profiling;
end;
/

spool off
