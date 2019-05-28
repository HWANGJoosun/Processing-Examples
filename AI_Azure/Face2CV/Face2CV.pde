/*********** 카메라 관련 변수 ***********/
import processing.video.*;
Capture cam;
int camW = 640, camH = 480;

/*********** 작동 관련 ***********/
boolean activate = false;
boolean blink = false;

/*********** 이미지 관련 변수 ***********/
PImage sample;
String fileName;  //이피지 파일의 이름
String fileDir;   //이미지 파일의 경로
String file;      //이미지의 경로 + 이름

/*********** 서버의 응답 관련 변수 ***********/
String postResult;  //서버의 응답을 저장할 변수

/*********** 이미지 시각화 관련 변수 ***********/
PFont font;

void setup() {
  size(640, 480);
  println("AZURE Face::Detect");

  //서버에 전송할 파일을 특정하여 불러옴
  fileName = "sample.jpg";
  fileDir = sketchPath()+"/data/"; 
  file = fileDir+fileName; 
  sample = loadImage(file);

  //화면에 표시할 글꼴 설정
  font = createFont("Gulim", 15);
  textFont(font);

  //카메라 설정 
  String[] cameras = Capture.list();
  if (cameras == null) {
    println("Failed to retrieve the list of available cameras, will try the default...");
    cam = new Capture(this, camW, camH);
  } 
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    printArray(cameras);
    cam = new Capture(this, cameras[3]);
    cam.start();
  }
}
void draw() {
  //카메라 이미지를 화면에 표시함
  if (cam.available() == true) {
    cam.read();
  }
  image(cam, 0, 0, camW, camH);
  if (activate) {                //작동 시작하면
    saveCamImage(cam);           //카메라 이미지를 저장
    thread("postImage"); //서버의 주소(url)로 이미지를 전송하고 서버의 응답을 회수함
    activate = false;            //작동 정지
  }
  //서버가 응답을 했을 경우, 응답을 분석하여 화면에 시각화함
  if (postResult != null && postResult != "") {
    JSONObject jo = parseJSONObject(postResult);
    println(jo);
    displayCVAnalyzeReqults(jo);
    blink = false;
    postResult = "";
  } 
  if (blink) {
    if (frameCount % 10 < 5) {
      fill(255, 0, 0);
    } else {
      fill(255);
    }
    noStroke();
    ellipse(10, 10, 10, 10);
  }
}

void mousePressed() {          //마우스를 누르면,
  activate = true;             //작동 시작
  blink = true;                //깜빡임 시작
  postResult = "";             //이전의 인식 결과 제거
}

void saveCamImage(PImage camImage) {
  PImage sample = camImage.get(); 
  sample.resize(camW,camH);
  sample.save(file);
}

void postImage() {
  println("*********************");
  println("!!! Posting Image !!!");
  println("*********************");
  // Azure가 정의한 규약에 따라 POST Request 구조화
  PostRequest post = new PostRequest(url);
  post.addHeader("Content-Type", "application/octet-stream");  //Request Header
  post.addHeader("Ocp-Apim-Subscription-Key", apiKey);         //Request Header
  post.addDataFromFile(file);                                  //Request Body
  post.send();                                                 //서버에 POST 방식으로 전송

  postResult = post.getContent();                       //서버의 응답 회수
  println(postResult);                                         //회수한 응답 출력
}

//JSON 객체를 분석하여 데이터를 추출하고 시각화
void displayObject(JSONObject jsonObject) {
}

//서버로 부터 회수한 JSON 배열의 각 객체를 displayFaceRectangle() 함수로 처리
void displayArray(JSONArray jsonArray) {
  for (int i=0; i<jsonArray.size(); i++) {
    JSONObject jsonObject = jsonArray.getJSONObject(i);
    displayObject(jsonObject);
  }
}

void displayCVAnalyzeReqults(JSONObject jsonObject) {
  JSONObject description = jsonObject.getJSONObject("description");
  JSONArray tagsArray = description.getJSONArray("tags");
  //println(tagsArray); 
  /**** tagsArray를 tags로 변환 ****/
  String tags = "";
  for (int i = 0; i< tagsArray.size(); i++) {
    tags+=tagsArray.get(i);
    if (i < tagsArray.size() -1) {
      tags+=",";
    }
  }
  println(tags);
  JSONObject captions = description.getJSONArray("captions").getJSONObject(0);
  float confidence = captions.getFloat("confidence");
  String text = captions.getString("text");
  String caption = text + "[comfidence=" + confidence + "]";
  println(caption);
}
