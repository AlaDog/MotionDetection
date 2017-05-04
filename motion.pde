//SOURCE: https://www.videvo.net/video/busy-tokyo-motorway/5754/
//This program can need a ton of ram!

ArrayList<PImage> output;
ArrayList<PGraphics> overlay;
ArrayList<PGraphics> borders;

int iterator = 0;
int end = 200; //457;

int k = 5; //5x5 pixels
int neigh = 5; //5x5 blocks
int gridX = 96;
int gridY = 54;

PVector[][] displace = new PVector[gridX][gridY];
boolean[][] binDis = new boolean[gridX][gridY]; //motion overlay
boolean[][] borderDis = new boolean[gridX][gridY]; //border overlay

void setup() {
  size(480, 270);
  frameRate(25);

  output = new ArrayList<PImage>(end);
  overlay = new ArrayList<PGraphics>(end);
  borders = new ArrayList<PGraphics>(end);

  for (int i = 1; i <= end; i++) {  //load image sequence
    output.add(loadImage("car (" +i+ ").png"));
    println("Loaded", int((float)i/end*100) + "%");
  }

  for (int frame = 0; frame < end-1; frame++) { //FOR EACH FRAME
    PImage current = output.get(frame); //load the 2 frames
    PImage next = output.get(frame+1);

    current.loadPixels();
    next.loadPixels();

    //CORE ALGORITHM
    for (int blockX = 0; blockX < gridX; blockX++) {
      for (int blockY = 0; blockY < gridY; blockY++) { //FOR EACH BLOCK

        float minSSD = Float.POSITIVE_INFINITY; //new min for block
        int locX = blockX * k;
        int locY = blockY * k;

        for (int neighX = -(int)neigh/2; neighX <= (int)neigh/2; neighX++) {
          for (int neighY = -(int)neigh/2; neighY <= (int)neigh/2; neighY++) { //FOR EACH NEIGHBOUR
            float ssd = Float.POSITIVE_INFINITY;
            try {
              ssd = 0;
              for (int x = 0; x < k; x++) {
                for (int y = 0; y < k; y++) { //FOR EACH PIXEL
                  int locCurrent = locX + x + ((locY + y) * width);
                  int locNext = (locX + (neighX * k) + x) +  ((locY + (neighY * k) + y) * width);
                  //FOR EACH COLOUR
                  ssd += sq(red(current.pixels[locCurrent]) - red(next.pixels[locNext]));
                  ssd += sq(green(current.pixels[locCurrent]) - green(next.pixels[locNext]));
                  ssd += sq(blue(current.pixels[locCurrent]) - blue(next.pixels[locNext]));
                }
              }
            } 
            catch(ArrayIndexOutOfBoundsException aioobE) {
            }

            if (ssd < minSSD) {
              minSSD = ssd;
              displace[blockX][blockY] = new PVector(neighX, neighY, sqrt(minSSD)); //record direction
              binDis[blockX][blockY] = sqrt(minSSD) > 120.0; //threshold out tiny movments
            }
          }
        }
      }
    }

    borderDis = dilate(binDis, 5); //create a border around object
    borderDis = erodeSub(borderDis, 3);


    binDis = dilate(binDis, 3); //only show motion near edges of objects
    binDis = erodeSub(binDis, 5);

    PGraphics frameOverlay = createGraphics(width, height);
    PGraphics border = createGraphics(width, height);
  
    //DRAW OVERLAYS
    frameOverlay.beginDraw();
    border.beginDraw();
    frameOverlay.noStroke();
    border.noStroke();
    for (int xDisplace = 0; xDisplace < gridX; xDisplace++) {
      for (int yDisplace = 0; yDisplace < gridY; yDisplace++) {
        float diff = displace[xDisplace][yDisplace].z;
        if (binDis[xDisplace][yDisplace]) {
          frameOverlay.fill(255, diff);
          frameOverlay.rect(xDisplace*k, yDisplace*k, k, k);
        }
        border.fill(255, borderDis[xDisplace][yDisplace]?255:0);
        border.rect(xDisplace*k, yDisplace*k, k, k);
      }
    }
    frameOverlay.endDraw();
    border.endDraw();
    
    overlay.add(frameOverlay);
    borders.add(border);
    println("Processed", int((float)frame/end*100) + "%");
  }
  println("Processed 100%, playing output");
}

void draw() { //once processing is done
  background(0);
  image(output.get(iterator+1), 0, 0); //main output
  image(overlay.get(iterator), 0, 0); //motion detected overlay
  if (mouseX > width/2) { //optional
    image(borders.get(iterator), 0, 0); //border highlight
  }

  iterator++;
  if (iterator == end-2) { //loop video
    iterator = 0;
  }
}

boolean[][] dilate(boolean[][] input, int kernal) { //dilation algorithm, assumes square kernal
  boolean[][] output = new boolean[input.length][input[0].length];
  for (int x = 0; x < gridX; x++) {
    for (int y = 0; y < gridY; y++) {
      boolean done = false;
      for (int kX = 0; kX < kernal; kX++) {
        for (int kY = 0; kY < kernal; kY++) {
          try {
            int totalX = x + kX-(int)kernal/2;
            int totalY = y + kY-(int)kernal/2;
            if (input[totalX][totalY]) {
              done = true;
            }
          } 
          catch (ArrayIndexOutOfBoundsException aioobE) {
          }
        }
      }
      output[x][y] = done;
    }
  }
  return output;
}

boolean[][] erodeSub(boolean[][] input, int kernal) { //erosion algorithm, assumes square kernal, also subtracts
  boolean[][] output = new boolean[input.length][input[0].length];
  for (int x = 0; x < gridX; x++) {
    for (int y = 0; y < gridY; y++) {
      boolean done = true;
      for (int kX = 0; kX < kernal; kX++) {
        for (int kY = 0; kY < kernal; kY++) {
          try {
            int totalX = x + kX-(int)kernal/2;
            int totalY = y + kY-(int)kernal/2;
            if (!input[totalX][totalY]) {
              done = false;
            }
          } 
          catch (ArrayIndexOutOfBoundsException aioobE) {
          }
        }
      }
      output[x][y] = input[x][y] && !done;
    }
  }
  return output;
}