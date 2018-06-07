// todo: don't allow point to move when dragged
// todo: allow throw velocity

int pointRadius = 20;
int sourceRadius = 40;
int logInterval = 500;

// colors
HashMap<String, Integer> colors = new HashMap<String, Integer>();

// mechanics classes
class Vector {
  private double r;
  private double t;
  Vector(double r, double t) {
    this.r = r;
    this.t = t;
  }
  double getX() {
    return this.r * Math.cos(this.t);
  }
  double getY() {
    return this.r * Math.sin(this.t);
  }
  Vector add(Vector v) {
    double newX = this.getX() + v.getX();
    double newY = this.getY() + v.getY();
    double newR = -Util.dist(newX, newY);
    double newT = Util.ang(newX, newY);
    return new Vector(newR, newT);
  }
  void draw(double x, double y, double l) {
    line((float) x, (float) y, (float) (x+this.getX() * l), (float) (y+this.getY() * l));
  }
}
// TODO: declare abstract and formalize subclassing?
class Point {
  private double x;
  private double y;
  private double r;
  Point(double x, double y) {
    this.setPos(x, y);
    this.r = pointRadius;
  }
  Point(double x, double y, double r) {
    this.setPos(x, y);
    this.r = r;
  }
  double getX() {
    return this.x;
  }
  double getY() {
    return this.y;
  }
  double getR() {
    return this.r;
  }
  void setPos(double x, double y) {
    this.x = x;
    this.y = y;
  }
  void setR(double r) {
    this.r = r;
  }
  
  // dummy functions
  void draw() {}
  void updatePosition(boolean bounded) {}
  void updatePosition() {}
  void pull(double x, double y) {}
}
class TargetPoint extends Point {
  TargetPoint(double x, double y) {
    super(x, y);
  }
  void draw() {
    noStroke();
    fill(colors.get("black"));
    ellipse((float) this.getX(), (float) this.getY(), 30, 30);
    fill(colors.get("white"));
    ellipse((float) this.getX(), (float) this.getY(), 20, 20);
    fill(colors.get("black"));
    ellipse((float) this.getX(), (float) this.getY(), 10, 10);
  }
}
class MobilePoint extends Point {
  private Vector v;
  private Vector a;
  MobilePoint(double x, double y) {
    super(x, y);
    this.v = new Vector(0, 0);
    this.a = new Vector(0, 0);
  }
  void draw() {
    stroke(colors.get("black"));
    fill(colors.get("black"));
    ellipse((float) this.getX(), (float) this.getY(), (float) this.getR(), (float) this.getR());
    stroke(colors.get("blue"));
    this.v.draw(this.getX(), this.getY(), 10);
    stroke(colors.get("red"));
    this.a.draw(this.getX(), this.getY(), 100);
  }
  void updatePosition(boolean bounded) {
    if(!bounded) {
      this.setPos(this.getX() + this.v.getX(), this.getY() + this.v.getY());
    } else {
      this.setPos(
        Math.max(0, Math.min(width, this.getX() + this.v.getX())),
        Math.max(0, Math.min(width, this.getY() + this.v.getY()))
      );
    }
  }
  void updatePosition() {
    this.updatePosition(false);
  }
  void setA(Vector a) {
    this.a = a;
  }
  void setV(Vector v) {
    this.v = v;
  }
  Vector getA() {
    return this.a;
  }
  Vector getV() {
    return this.v;
  }
}
class GravityPoint extends MobilePoint {
  private double g;
  GravityPoint(double x, double y, double g) {
    super(x, y);
    this.g = g;
  }
  void pull(double sourceX, double sourceY) {
    double d = Math.max(Util.dist(sourceX - this.getX(), sourceY - this.getY()), 5);
    double r = -this.g/d;
    double t = Util.ang(sourceX - this.getX(), sourceY - this.getY());
    this.setA(new Vector(r, t));
    this.setV(this.getV().add(this.getA()));
  }
}
class SourcePoint extends Point {
  SourcePoint(double x, double y) {
    super(x, y);
    this.setR(sourceRadius);
  }
  void draw() {
    fill(colors.get("white"));
    stroke(colors.get("red"));
    ellipse((float) this.getX(), (float) this.getY(), (float) this.getR(), (float) this.getR());
  }
}
class UtilStatic {
  int randInt(int max) {
    return (int) Math.floor(Math.random() * max);
  }
  double dist(double x, double y) {
    return Math.sqrt(x * x + y * y);
  }
  double ang(double x, double y) {
    return Math.atan(y / x) + (x >= 0 ? PI : 0);
  }
  // method overloading for use with points for convenience
  // for some reason this doesn't work, so accounted for manually
  double counter = 0;
  double dist(Point p1, Point p2) {
    if(!(p1 instanceof Point)) {
      return Math.sqrt(p1 * p1 + p2 * p2);
    } else {
      return this.dist(p1.getX() - p2.getX(), p1.getY() - p2.getY());
    }
  }
  double ang(Point p1, Point p2) {
    if(!(p1 instanceof Point)) {
      return Math.atan(p2 / p1) + (p1 >= 0 ? PI : 0);
    } else {
      return this.ang(p1.getX() - p2.getX(), p1.getY() - p2.getY());
    }
  }
}
UtilStatic Util = new UtilStatic();
class DraggablePointStatic {
  ArrayList<DraggablePoint> points = new ArrayList<DraggablePoint>();
  int activePoint = -1;
  boolean isMouseDragged = false;
  void drawAll() {
    fill(0x00000000);
    for(int i = 0; i < points.size(); i++) {
      points.get(i).draw();
    }
  }
  void onMousePressed() {
    for(int i = 0; i < this.points.size(); i++) {
      if(Util.dist(this.points.get(i), new Point(mouseX, mouseY)) < this.points.get(i).getR()) {
        this.activePoint = i;
        this.points.get(this.activePoint).setIsDragged(true);
        return;
      } 
    }
  }
  void onMouseDragged() {
    if(this.activePoint == -1) return;
    this.isMouseDragged = true;
    this.points.get(this.activePoint).setPos(mouseX, mouseY);
  }
  void onMouseReleased() {
    if(this.activePoint == -1) return;
    this.points.get(this.activePoint).setIsDragged(false);
    this.activePoint = -1;
    this.isMouseDragged = false;
  }
}
DraggablePointStatic DraggablePointUtil = new DraggablePointStatic();
class DraggablePoint extends MobilePoint {
  private ElasticBand eb = null;
  private boolean isDragged = false;
  DraggablePoint(double x, double y) {
    super(x, y);
    DraggablePointUtil.points.add(this);
  }
  DraggablePoint(double x, double y, ElasticBand eb) {
    super(x, y);
    DraggablePointUtil.points.add(this);
    this.eb = eb;
  }
  void setEb(ElasticBand eb) {
    this.eb = eb;
  }
  void setIsDragged(boolean isDragged) {
    this.isDragged = isDragged;
  }
  boolean isElasticBand() {
    return this.eb != null;
  }
  boolean getIsDragged() {
    return this.isDragged;
  }
  void setPos(double x, double y) {
    if(this.isElasticBand()) {
      this.eb.drag(this, x, y);
    }
    super.setPos(x, y);
  }
  void setPosElasticRegular(double x, double y) {
    super.setPos(x, y);
  }
  void updatePosition(boolean bounded) {
    if(this.getIsDragged()) return;
    super.updatePosition(bounded);
  }
  void updatePosition() {
    this.updatePosition(false);
  }
  void draw() {
    fill(colors.get("green"));
    ellipse(this.getX(), this.getY(), this.getR(), this.getR());
  }
}
class ElasticBandStatic {
  ArrayList<ElasticBand> bands = new ArrayList<ElasticBand>();
  void drawAndUpdateAll() {
    for(int i = 0; i < bands.size(); i++) {
      this.bands.get(i).updatePointVelocities();
      this.bands.get(i).updatePointPositions();
      line(
        this.bands.get(i).getP1().getX(),
        this.bands.get(i).getP1().getY(),
        this.bands.get(i).getP2().getX(), 
        this.bands.get(i).getP2().getY());
    }
  }
}
ElasticBandStatic ElasticBandUtil = new ElasticBandStatic();
class ElasticBand {
  private DraggablePoint p1;
  private DraggablePoint p2;
  private double k;
  private double l;
  ElasticBand(DraggablePoint p1, DraggablePoint p2, double k, double l) {
    this.p1 = p1;
    this.p2 = p2;
    this.p1.setEb(this);
    this.p2.setEb(this);
    this.l = l;
    this.k = k;
    ElasticBandUtil.bands.add(this);
  }
  ElasticBand(double x1, double y1, double x2, double y2, double k, double l) {
    this.p1 = new DraggablePoint(x1, y1, this);
    this.p2 = new DraggablePoint(x2, y2, this);
    this.k = k;
    this.l = l;
    ElasticBandUtil.bands.add(this);
  }
  DraggablePoint getP1() {
    return this.p1;
  }
  DraggablePoint getP2() {
    return this.p2;
  }
  double getK() {
    return this.k;
  }
  boolean drag(DraggablePoint p, double x, double y) {
    if(p == this.p1) {
      // point one is being dragged
      this.p1.setPosElasticRegular(x, y);
      this.p1.setV(new Vector(0, 0));
      return true;
    } else if(p == this.p2) {
      // point two is being dragged
      this.p2.setPosElasticRegular(x, y);
      this.p2.setV(new Vector(0, 0));
      return true;
    } else {
      // error
      return false;
    }
  }
  void updatePointVelocities() {
    // calculate acceleration (proportional to force) using Hooke's Law
    double a = (Util.dist(this.getP1(), this.getP2()) - this.l) * this.getK();
    // add velocity toward other point, proportional to acceleration
    double t1 = Util.ang(this.getP1(), this.getP2());
    double t2 = Util.ang(this.getP2(), this.getP1());
    this.getP1().setV(this.getP1().getV().add(new Vector(a, t1)));  // TODO: tweak this as necessary
    this.getP2().setV(this.getP2().getV().add(new Vector(a, t2)));
  }
  void updatePointPositions() {
    this.getP1().updatePosition();
    this.getP2().updatePosition();
  }
}

// basic setup
void setup() {
  // set up size
  size(600, 600);

  // set colors
  colors.put("blue", 0xff0000ff);
  colors.put("green", 0xff00ff00);
  colors.put("red", 0xffff0000);
  colors.put("black", 0xff000000);
  colors.put("white", 0xffffffff);
  
  // create an elastic band
  new ElasticBand(100, 100, 500, 500, 0.01, 50);
  new ElasticBand(50, 300, 300, 400, 0.05, 200);
}

// main draw function
void draw() {
  // clear background
  background(0xffaffafa);

  ElasticBandUtil.drawAndUpdateAll();
  DraggablePointUtil.drawAll();
}

// event handlers
void mousePressed() {
  DraggablePointUtil.onMousePressed();
}
void mouseDragged() {
  DraggablePointUtil.onMouseDragged();
}
void mouseReleased() {
  DraggablePointUtil.onMouseReleased();
}
