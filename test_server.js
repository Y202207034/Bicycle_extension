const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

app.use(express.json());
app.use(express.static(path.join(__dirname)));

// Flutter 앱에서 GPS 데이터 받는 API
app.post('/location', (req, res) => {
  const { lat, lng } = req.body;
  console.log(`위치 수신: ${lat}, ${lng}`);

  // 웹사이트로 실시간 전송
  io.emit('locationUpdate', { lat, lng });

  res.json({ success: true });
});

server.listen(3000,'192.168.201.102', () => {
  console.log('✅ 서버 실행 중 → http://192.168.201.102:3000');
});