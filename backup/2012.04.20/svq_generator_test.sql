create or replace package svg_test as
 
	procedure run(a_str varchar2);
	procedure print_all_svg;
end;
/
show err

create or replace package body svg_test as
  
  TYPE BlockType IS RECORD (
    x NUMBER(1),
    y NUMBER(1),
    length number(1),
    orientation varchar2(1),
    marker varchar2(1)
  );

  
  type blocksArrayType IS TABLE OF BlockType INDEX BY binary_integer;

  
  function stringtoblocks(a_str varchar2) return blocksarraytype is
  
    v_filler varchar2(1) := '0';
    v_done varchar2(30) := ' ';
    v_m varchar2(1);
    blocks blocksarraytype;
    v_grid_size number := 6;
    id number := 0;
  
  begin
    for i in 1..v_grid_size * v_grid_size loop
      v_m := substr(a_str, i , 1);
      if v_m <> v_filler and instr(v_done, v_m) = 0 then
      
        blocks(id).x := mod((i - 1),v_grid_size);
        blocks(id).y := trunc((i - 1)/v_grid_size);
        blocks(id).length := v_grid_size * v_grid_size - length(replace(a_str,v_m,''));
        blocks(id).marker := lower(v_m);

        if blocks(id).x < v_grid_size and substr(a_str, i + 1, 1) = blocks(id).marker then
          blocks(id).orientation := 'h';
        elsif blocks(id).y < v_grid_size and substr(a_str, i + v_grid_size, 1) = blocks(id).marker then
          blocks(id).orientation := 'v';
        else
          raise_application_error(-20000, 'Can not determine block orientation : block = ' || blocks(id).marker);
        end if;

        v_done := v_done || blocks(id).marker;
        id := id + 1;
      end if;
    end loop;
    
    return(blocks);
  end;
  


	procedure run(a_str varchar2) is
	
		rect_width number(10) := 50;
		frame_width number := 6;
		xoffset number := 460;
		yoffset number := 50;
		
		background_color varchar2(50) := 'RGB(103,73,30)';
		frame_color varchar2(50) := 'RGB(168,123,45)';
		block_color_wood varchar2(50) := 'RGB(220,141,61)';
		block_color_red varchar2(50) := 'RGB(194,33,2)';
			
		blocks blocksarraytype;
		block  blocktype;
		width number(10);
		height number(10);
		x number;
		y number;

		
		block_color varchar2(50);
		
		
	begin
		width := 6 * rect_width + 2 * frame_width;
		height := width;
		
		x := xoffset;
		y := yoffset;
		dbms_output.put_line('	<rect x="'||x||'" y="'||y||'" rx="2" ry="2" width="'||width||'" height="'||height||'" style="fill:'||background_color||';stroke:'||frame_color||';stroke-width:5;opacity:1"/>');

		blocks := stringtoblocks(a_str);
		for i in 0..blocks.count - 1 loop
		
			block := blocks(i);
			
			x := xoffset + block.x * rect_width + frame_width;
			y := yoffset + block.y * rect_width + frame_width;
			block_color := block_color_wood;
			
			if block.orientation = 'h' then
				width := block.length * rect_width;
				height:= rect_width;
				if block.marker = 'X' then block_color := block_color_red; end if;
			else
				width := rect_width;
				height:= block.length * rect_width;
			end if;

			dbms_output.put_line('	<rect x="'||x||'" y="'||y||'" rx="8" ry="8" width="'||width||'" height="'||height||'" style="fill:'||block_color||';stroke:Sienna;stroke-width:3;opacity:1"/>');				


		end loop;
	end;



	procedure print_block_svg(a_block blocktype) is
	
		rect_width number(10) := 50;
		frame_width number := 6;
		xoffset number := 460;
		yoffset number := 50;
		
		background_color varchar2(50) := 'RGB(103,73,30)';
		frame_color varchar2(50) := 'RGB(168,123,45)';
		block_color_wood varchar2(50) := 'RGB(220,141,61)';
		block_color_red varchar2(50) := 'RGB(194,33,2)';
			
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
--      dbms_output.put_line('skipped : '||block.orientation||block.x||block.y);
      return; end if;
      if lower(block.orientation)  = 'v' and block.y + block.length > 6 then return; end if;
      
			x := xoffset + block.x * rect_width + frame_width;
			y := yoffset + block.y * rect_width + frame_width;
			block_color := block_color_wood;
			if lower(a_block.marker) = 'x' then id := 'x'; else id := a_block.orientation; end if;
			
			
			if lower(block.orientation) = 'h' then
				width := block.length * rect_width;
				height:= rect_width;
				if lower(block.marker) = 'x' then block_color := block_color_red; end if;
				if block.length = 3 then id := 'H'; end if;
			else
				width := rect_width;
				height:= block.length * rect_width;
				if block.length = 3 then id := 'V'; end if;
			end if;

      id := id || block.x || block.y;
     
			dbms_output.put_line('	<rect id="'||id||'" x="'||x||'" y="'||y||'" rx="8" ry="8" width="'||width||'" height="'||height||'" style="visibility:hidden;fill:'||block_color||';stroke:Sienna;stroke-width:3;opacity:1"/>');				

	end;

  procedure print_all_svg is
    block blocktype;
  begin
    dbms_output.put_line('<svg>');
    for x in 0..5 loop
      for y in 0..5 loop
        block.x := x;
        block.y := y;
        
        block.length := 2;
        block.orientation := 'v';
        print_block_svg(block);
        block.orientation := 'h';
        print_block_svg(block);
        block.length := 3;
        block.orientation := 'V';
        print_block_svg(block);
        block.orientation := 'H';
        
        print_block_svg(block);        
      end loop;
    end loop;
    
    block.length := 2;
    block.y := 2;
    block.orientation := 'h';
    block.marker := 'x';

    for x in 0..4 loop
      block.x := x;
      print_block_svg(block);
    end loop;
    
    dbms_output.put_line('</svg>');
  end;

end;
/


end;
/


show err

set feedback off
spool d:\tmp\2012.04.20\svg.svg

begin
/*
  dbms_output.put_line('<?xml version="1.0" standalone="no"?>');
  dbms_output.put_line('<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"');
  dbms_output.put_line('"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">');
  dbms_output.put_line('<svg xmlns="http://www.w3.org/2000/svg" version="1.1">');
  svg_test.run('AA0BC0DDDBC0XX0BE0F0GGE0F0IJJ0HHI000') 
  dbms_output.put_line('</svg>');
*/  
  svg_test.print_all_svg;
end;
/

spool off
set feedback on

-- host start d:\Work\2012.02.24_Unblockme_solver\2012.04.20\test.svg
