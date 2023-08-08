var isIE = document.all ? true : false;

// SVG constants
var cell_width          = 50;
var main_frame_width    = 6;
var block_frame_width   = 3;
var xoffset             = 460;
var yoffset             = 60;
var board_corner_radius = 2;
var block_corner_radius = 8;

var board_color       = 'RGB(103,73,30)';
var main_frame_color  = 'RGB(168,123,45)';
var block_frame_color = 'Sienna';
var block_color_wood  = 'RGB(220,141,61)';
var block_color_red   = 'RGB(194,33,2)';

//implement Set type
var Set = function() {}
Set.prototype.add = function(o) { this[o] = true; }
Set.prototype.remove = function(o) { delete this[o]; }

//global variables
var c='0';
var board_width = (6 * cell_width + 2 * main_frame_width);
var paper;
var blocks = new Array();
var board = [[c,c,c,c,c,c],[c,c,c,c,c,c],[c,c,c,c,c,c],[c,c,c,c,c,c],[c,c,c,c,c,c],[c,c,c,c,c,c]];
var markers = {A:0,B:0,C:0,D:0,E:0,F:0,G:0,H:0,I:0,J:0,K:0,L:0,M:0,N:0,O:0,P:0,Q:0,R:0,X:0};
var dummy;
var dummies = [];
var message;


function init() {
    document.onmousemove = mouseMove;
    document.onkeypress = keyPressed;
    document.oncontextmenu = function(e){
                              if (e.target.raphaelid) return false;
                              return true;
                            };
    
    xoffset = (window.innerWidth - board_width)/2;
    paper = Raphael(0, 0, window.innerWidth, board_width + yoffset + 2.5*cell_width);


    //BOARD
    var board_rect = paper.rect(xoffset, yoffset, board_width, board_width, board_corner_radius);
    board_rect.attr({
        "stroke": main_frame_color,
        "stroke-width": main_frame_width,
        "fill" : board_color
    });

    // board grid
    for (var i=1; i<6; i++) {
      var str = "M"+ (xoffset + main_frame_width + i*cell_width) + " " + (yoffset + main_frame_width/2) + "v" + (6 * cell_width + main_frame_width);
      var p = paper.path(str);
      p.attr({"stroke": main_frame_color});

      str = "M"+ (xoffset + main_frame_width/2) + " " + (yoffset + main_frame_width + i*cell_width) + "h" + (6 * cell_width + main_frame_width);
      p = paper.path(str);
      p.attr({"stroke": main_frame_color});
    }

    //Dummies 
    dummies.push(makeRect('h',2));
    dummies.push(makeRect('h',3));
    dummies.push(makeRect('v',2));
    dummies.push(makeRect('v',3));

    for (var i=0; i<dummies.length; i++) {
      dummies[i].mousedown(mDown);
      dummies[i].mouseup(mUp);
    } 

    dummy = dummies[0];
}

function mDown(e) {
    return false;
}

function indexOfBlock (block) {
  for (var i=0; i<blocks.length; i++) {
    if (blocks[i] == block)
      return i;
  }
  return -1;
}

function setXBlock() {
  var block = null;
  for (var i=0; i<blocks.length; i++) {
    if ((blocks[i].cy == 2 && blocks[i].orientation == 'h' && blocks[i].size == 2) && (block == null || block.cx < blocks[i].cx)) {
      block = blocks[i];
    }
  }
  
  
  if (block == null || block.marker == 'X')
    return;

  for (var i=0; i<blocks.length; i++) {
    if (blocks[i].marker == 'X') {
      blocks[i].marker = marker();
      markers[blocks[i].marker] = 1;
      setBlockStyle(blocks[i],"bw");
    }
  }	
  
  markers[block.marker] = 0;
  block.marker = 'X';
  markers['X'] = 1;
  setBlockStyle(block,"rw");
  board = boardfromblocks (blocks);
  label = document.getElementById("boardString");
  label.innerHTML = boardToString();

}

function addBlock(orientation, size, cx, cy) {
      var block;
      for (var i=0; i<dummies.length; i++){
        if (dummies[i].orientation == orientation && dummies[i].size == size) {
          block = dummies[i].clone();
          break;
        }
      }
      
      block.orientation = orientation.valueOf();
      block.size = size.valueOf();
      block.marker = marker();
      markers[block.marker] = 1;
      block.cx = cx.valueOf();
      block.cy = cy.valueOf();
      block.unmousedown;
      block.unmouseup;
      blocks.push(block);
      
      doPlace(block, cx, cy, true);
      if (cy == 2 && orientation == 'h' && size == 2) setXBlock();
}

function refreshDummy() {
  placeDummyAtCell(dummy.cx, dummy.cy, true);
}

function mUp(e) {
  if (e.which == 3) {
    shuffleDumies();
  } else {
    var block;
    
    if (canPlace(dummy, dummy.cx, dummy.cy)) {
      addBlock(dummy.orientation.valueOf(), dummy.size.valueOf(), dummy.cx.valueOf(), dummy.cy.valueOf());
      refreshDummy();
    } else {
      block = blockUnderDummy();
      if (block != null) {
        blocks.splice(indexOfBlock(block), 1);
        doPlace(block, block.cx, block.cy, false);
        refreshDummy();
        if (dummy.cy == 2 && dummy.orientation == 'h' && dummy.size == 2) setXBlock();
      } 
    }
  }	

  return true;
}				


function setBlockStyle(block, style) {
/*
    "rw" = red wood
    "bw" = brown wood
    "r" = red frame
    "y" = yellow frame
    "g" = green frame				
*/
    
    if         (style == 'bw') {
      block.attr({"stroke":block_frame_color, "stroke-width":block_frame_width, "fill":block_color_wood, "fill-opacity":1});
    } else if (style == 'rw') {
      block.attr({"stroke":block_frame_color, "stroke-width":block_frame_width, "fill":block_color_red, "fill-opacity":1});
    } else if (style == 'r') {
      block.attr({"stroke":"RGB(250,0,0)", "fill-opacity":0});
    } else if (style == 'y') {
      block.attr({"stroke":"RGB(255,255,100)", "fill-opacity":0});
    } else if (style == 'g') {
      block.attr({"stroke":"RGB(0,200,0)", "fill-opacity":0});
    }

}

function makeRect(orientation, size) {
    var rect;
    
    if (orientation == 'v') {
      rect = paper.rect(0, 0, cell_width, size*cell_width, block_corner_radius);
    } else {
      rect = paper.rect(0, 0, size*cell_width, cell_width, block_corner_radius);
    }	
    
    rect.attr({"stroke-width":block_frame_width, "fill":block_color_wood, "fill-opacity":0});
    rect.orientation = orientation;
    rect.size = size;
    rect.marker = ' ';
    rect.cx = -1;
    rect.cy = -1;

    rect.hide();
    return rect;
}



function blockUnderDummy() {
  var block;
  
  for (var i=0; i<blocks.length; i++) {
    block = blocks[i];
    if (block.cx == dummy.cx && block.cy == dummy.cy && block.size == dummy.size && block.orientation == dummy.orientation)
      return block;
  }
  
  return null;
}

function placeDummyAtCell(cx, cy, force) {

  if (cx >= 0 && cy >= 0) {
    
    var newx = xoffset + main_frame_width + cx * cell_width;
    var newy = yoffset + main_frame_width + cy * cell_width;
    var oldx = dummy.attr("x");
    var oldy = dummy.attr("y");

    if (newx != oldx || newy != oldy || force) {

      dummy.cx = cx;
      dummy.cy = cy;
      dummy.attr({"x":newx, "y":newy});
    
      if (canPlace(dummy, cx, cy)) {
        setBlockStyle(dummy,'g');
      } else if (blockUnderDummy() == null) {
        setBlockStyle(dummy,'y');
      } else {
        setBlockStyle(dummy,'r');
      }
        

      dummy.show();							
      dummy.toFront();
    }  
  } else {
    dummy.hide();
    dummy.attr({"x":0, "y":0});
  }				
}

function mouseMove(evt) {
  var mx = isIE ? window.event.clientX : evt.pageX;
  var my = isIE ? window.event.clientY : evt.pageY;
  
  var cell = cellUnderCoordinates(mx, my);
  placeDummyAtCell(cell.x, cell.y);
  //window.status = "Mouse: X=" + mx + ",Y=" + my + " cell= (" + cell.x + "," + cell.y + ")";
  return false;
}


function shuffleDumies() {
  var oldIdx = dummies.indexOf(dummy);
  var newIdx;
  
  if (oldIdx == 3) {
    newIdx = 0;
  } else { newIdx = oldIdx + 1;}

  //dummies[oldIdx].animate({ width:150, height:50 },150);					
  dummies[oldIdx].hide();
  var cell = cellUnderCoordinates(dummies[oldIdx].attr("x"), dummies[oldIdx].attr("y"));
  dummy = dummies[newIdx];
  placeDummyAtCell(cell.x, cell.y);
  dummies[oldIdx].attr({"x":10,"y":10});        
}

function keyPressed(e)
{
    if (null == e)
        e = window.event ;
        
    if (e.keyCode == 13)  {
      shuffleDumies();
    }

    return true;
}				


function marker() {
  for (key in markers) {
    if (markers[key] == 0) {
      return key;
    }
  }
}

function canPlace(block, cx, cy) {
  //if (block.attr('fill') == block_color_red && (cy != 2 || markers["X"] == 1)) {
  //	return false;
  //}

  var result = true;

  if (block.orientation == 'h') {
    result = (block.size + cx) <= 6;
    result = result && (board[(cx)][cy] == c) && (board[(cx + 1)][cy] == c);
    if (block.size == 3) {result = result && (board[(cx + 2)][cy] == c);}
  } else {
    result = (block.size + cy) <= 6;
    result = result && (board[(cx)][cy] == c) && (board[(cx)][cy + 1] == c);
    if (block.size == 3) {result = result && (board[(cx)][cy + 2] == c);}
  }

  return result;
}


function doPlace(block, cx, cy, set) {
  var chr;
  
  setBlockStyle(block, "bw");
  
  if (set) {
    chr = block.marker;
  } else {
    chr = c;
  }

  for (var i=0; i<block.size; i++) {
    if (block.orientation == 'h') {
      board[(i + cx)][cy] = chr;
    } else {
      board[cx][(i + cy)] = chr;
    }
  }

  if (set) {
    var x = xoffset + main_frame_width + cx * cell_width;
    var y = yoffset + main_frame_width + cy * cell_width;
    block.attr({ x:x, y:y });
  } else {
    markers[block.marker] = 0;
    block.remove();
  }

  label = document.getElementById("boardString");
  label.innerHTML = boardToString() + "<br/>" + blocksToString2();
}



function cellUnderCoordinates(x, y) {
  var cell = new Object();

  cell.x = Math.floor((x - xoffset - main_frame_width)/cell_width);
  cell.y = Math.floor((y - yoffset - main_frame_width)/cell_width);
  if (cell.x < 0 || cell.x > 5 || cell.y < 0 || cell.y > 5){
    cell.x = -1;
    cell.y = -1;
  }

  return cell;
}


function boardToString() {
var result = '';
  for (var i=0; i<6; i++){
    for (var k=0; k<6; k++){
      result = result + board[k][i];
    }
  }
  
 return result; 
}


function blocksToString() {

  var brd = [[c,c,c,c,c,c],[c,c,c,c,c,c],[c,c,c,c,c,c],[c,c,c,c,c,c],[c,c,c,c,c,c],[c,c,c,c,c,c]];
  var block;
  var cx;
  var cy;
  var marker;
  var result = '';

  for (var i=0;i < blocks.length;i++) {
    block = blocks[i];
    cx = block.cx;
    cy = block.cy;
    
    marker = block.orientation.valueOf();
    if (block.size == 3) 
      marker = marker.toUpperCase();

    brd[cx][cy] = marker;

    if (block.orientation == 'h') {
      cx++;
      brd[cx][cy] = marker;
      if (block.size == 3) {cx++; brd[cx][cy] = marker;}
    } else {
      cy++;
      brd[cx][cy] = marker;
      if (block.size == 3) {cy++; brd[cx][cy] = marker;}
    }        
  }

  for (var i=0; i<6; i++){
    for (var k=0; k<6; k++){
      result = result + brd[k][i];
    }
  }

  return result;
}


function blocksToString2() {
  var result = '';
  for (var i=0;i < blocks.length;i++) {
    result += blocks[i].orientation + blocks[i].size + blocks[i].cx + blocks[i].cy;
  }
  return result;
}


function Log(aTxt,aInverse) {
  if (aInverse) {
    document.getElementById("txt").innerHTML = aTxt + "<br/>" + document.getElementById("txt").innerHTML;
  } else {
    document.getElementById("txt").innerHTML += aTxt + "<br/>";
  }
}


// ------------- Solution ----------------------------------
var steps = [];
var done = false;
var cnt = 0;
var solution_cnt = 0;
var bestsol_cnt = -1;
var bestsol_msec = -1;
var bestsol_lvl = -1;
var solution = [];
var index = 0;
var start = new Date().getTime();


function setSolutionEnv(on) {
  if (on) {
    document.getElementById("prevBtn").disabled = false;
    document.getElementById("nextBtn").disabled = false;
    document.getElementById("solveBtn").disabled = true;
    document.getElementById("moves").innerHTML = '0 / ' + (solution.length - 1);
  } else {
    document.getElementById("prevBtn").disabled = true;
    document.getElementById("nextBtn").disabled = true;
    document.getElementById("solveBtn").disabled = false;
    document.getElementById("moves").innerHTML = 'No solution available.';
    solution = [];
    index = 0;
    board = boardfromblocks (blocks);
  }
}

function buildSolution (x,y) {
  var step = steps[x][y];
  var idx = x.valueOf();
  solution = new Array();

  while (idx >= 0) {
    solution[idx] = step.position;
    step = step.parent;
    idx--;
  }

  //setSolutionEnv(true);
}


function registerPosition (a_parent, a_blockindex, a_newpos) {
  var pos = copyPosition(a_parent.position);
  var isSolution = false;

  if (pos[a_blockindex].orientation == 'h')  {
    pos[a_blockindex].cx = a_newpos;
    if (pos[a_blockindex].marker == 'X' && a_newpos == 4) {
      isSolution = true;
    }
  } else pos[a_blockindex].cy = a_newpos;

  var key = '';
  for (var i=0; i<pos.length; i++) {
    if (pos[i].orientation == 'h') key = key + pos[i].cx;
    else key = key + pos[i].cy;
  }

  if (keys[key]) {
    return false;
  } else {
    done = false;
    keys.add(key);
    var step = {parent:a_parent, position:pos};
    steps[lvl].push(step);
    if (isSolution) {
      cnt++;
      solution_cnt++;
      if (bestsol_lvl == -1) {
        bestsol_cnt = 1;
        bestsol_lvl = lvl;
      }	else if (bestsol_lvl == lvl) {
        bestsol_cnt++;
      }
      
      if (solution_cnt == 1) {
        buildSolution(lvl, (steps[lvl].length - 1));
        bestsol_msec = new Date().getTime() - start;
      }
    }
    return true;
  }
}


function allMoves (a_parent) {
  var brd = boardfromblocks (a_parent.position);
  var block;
  var canPlace;


  for (var i=0; i<a_parent.position.length; i++) {
    block = a_parent.position[i];

    if (block.orientation == 'h') {
      var x = block.cx;
      while (x > 0) {
        x--;
        if (brd[x][block.cy] == c) {registerPosition (a_parent, i, x);}
        else 	break;
      }

      x = block.cx +  block.size;
      while (x < 6) {
        if ((brd[x][block.cy] == c)) {registerPosition (a_parent, i, (x - block.size + 1));}
        else break;
        x++;
      }
    } else {
      var y = block.cy;
      while (y > 0) {
        y--;
        if (brd[block.cx][y] == c) {registerPosition (a_parent, i, y);}
        else break;
      }

      y = block.cy +  block.size;
      while (y < 6) {
        if ((brd[block.cx][y] == c)) {registerPosition (a_parent, i, (y - block.size + 1));}
        else break;
        y++;
      }
    }
  }

}

function boardfromblocks (a_position) {
  var brd = [[c,c,c,c,c,c],[c,c,c,c,c,c],[c,c,c,c,c,c],[c,c,c,c,c,c],[c,c,c,c,c,c],[c,c,c,c,c,c]];
  var block;
  var cx;
  var cy;

  for (var i=0;i<a_position.length;i++) {
    block = a_position[i];
    cx = block.cx;
    cy = block.cy;

    brd[cx][cy] = block.marker;

    if (block.orientation == 'h') {
      cx++;
      brd[cx][cy] = block.marker;
      if (block.size == 3) {cx++; brd[cx][cy] = block.marker;}
    } else {
      cy++;
      brd[cx][cy] = block.marker;
      if (block.size == 3) {cy++; brd[cx][cy] = block.marker;}
    }
  }

  return brd;
}

function pad(n,l) {
    return ('000000000' + n.toString()).substr(-l);
}

function copyPosition(oldPos) {
  var newPos = new Array();
  newPos.length = oldPos.length;
  for (var i=0; i<oldPos.length; i++) {
    block = {};
    block.cx = blocks[i].cx;
    block.cy = blocks[i].cy;
    block.size = blocks[i].size;
    block.orientation = blocks[i].orientation;
    block.marker = blocks[i].marker;

    newPos[i] = {"cx":oldPos[i].cx, "cy":oldPos[i].cy, "size":oldPos[i].size, "orientation":oldPos[i].orientation, "marker":oldPos[i].marker};
  }
  
  return newPos;
}


function solveBtnClick() {
  var tmp;
  var position = [];
  var block = {};

  start = new Date().getTime();
  document.getElementById("txt").innerHTML = '';
  //setSolutionEnv(false);

  for (var i=0; i<blocks.length; i++) {
    block = {};
    block.cx = blocks[i].cx;
    block.cy = blocks[i].cy;
    block.size = blocks[i].size;
    block.orientation = blocks[i].orientation;
    block.marker = blocks[i].marker;

    position.push(block);
  }

  keys = new Set();
  steps = [];

  lvl = 0;
  stepid = 0;

  var step0 = {position:position};
  var newpos;

  if (position[0].orientation == 'h') {
    newpos = position[0].cx;
  } else {
    newpos = position[0].cy;
  }

  steps.push([]);
  registerPosition (step0, 0, newpos);

  solution_cnt = 0;	
  while (done == false) {
    //Log(lvl + ' : ' + steps[lvl].length + ' : ' + cnt, true);
    lvl++;
    steps.push([]);
    done = true;
    cnt = 0;
    for (var i = 0; i < steps[lvl - 1].length; i++) {
      allMoves(steps[lvl - 1][i]);
    }
  }

  steps.pop();
  cnt = 0;
  for (var i = 0; i < steps.length; i++) {
    cnt += steps[i].length;
  }

  message  = 'Best solution (1/' + bestsol_cnt + ')/' + solution_cnt + ' : moves = ' + bestsol_lvl + ', execution time = ' + bestsol_msec + ' msec' + '<br/>';
  message += 'Boards explored : number = ' + cnt  + ' execution time = ' + (new Date().getTime() - start) + " msec" + "<br/>" ;
  Log(message);

}

// ------------- Solution presentation ----------------------------------

function setPosition(a_idx) {
  if (a_idx < 0 || a_idx > solution.length - 1) {
    return;
  }
  for (var i = 0; i < blocks.length; i++) {
    if (blocks[i].cx != solution[a_idx][i].cx || blocks[i].cy != solution[a_idx][i].cy) {
      var x = xoffset + main_frame_width + solution[a_idx][i].cx * cell_width;
      var y = yoffset + main_frame_width + solution[a_idx][i].cy * cell_width;

      blocks[i].animate({ x:x, y:y },150);
      blocks[i].cx = solution[a_idx][i].cx.valueOf();
      blocks[i].cy = solution[a_idx][i].cy.valueOf();
      document.getElementById("moves").innerHTML = a_idx + ' / ' + (solution.length - 1);
    }
  }
  index = a_idx;
}

function nextStep() {
  if (index == solution.length - 1) {
    index = -1;
  }
  setPosition(index + 1);
}

function prevStep() {
  if (index == 0) {
    index = solution.length;
  }        
  setPosition(index - 1);
}
// ------------- Solution presentation end ----------------------------------
