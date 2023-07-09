import asyncio
import http
import json
import logging
import signal
import sys
import telnetlib
from typing import Any, TypedDict

import websockets.server


class Request(TypedDict):
  jsonrpc: str
  method: str
  params: Any | None


class ErrorModel(TypedDict):
  code: int
  message: str
  data: Any | None


logging.basicConfig(
  level = logging.INFO,
  format = '%(asctime)s - %(name)s - %(levelname)-s - %(message)s',
)

logger = logging.getLogger('oremi-player')
USER_AGENT = 'Oremi Player/1.0.0'

def start(port: int = 3765):
  loop = asyncio.get_event_loop()
  stop = loop.create_future()

  try:
    logger.info('Opening VLC LUA CLI...')
    vlc_client = telnetlib.Telnet('localhost', 4212)
  except ConnectionRefusedError:
    logger.error('Unable to connect to VLC CLI')
    sys.exit(1)

  def send_vlc_command(command: str):
    vlc_client.write((command + '\n').encode('ascii'))
    response = vlc_client.read_until(b'>')
    print(response.decode('ascii'))
    return response.decode('ascii')

  async def send_response(
    websocket,
    request_id: int,
    *,
    result: Any | None = None,
    error: ErrorModel | None = None,
  ):
    json_response = {
      'jsonrpc': '2.0',
      'id': request_id,
    }
    if result:
      json_response['result'] = result
    elif error:
      json_response['error'] = error
    logger.info(f'Sending response: {json_response}')
    await websocket.send(json.dumps(json_response).encode('utf-8'))

  async def handle_websocket(websocket, path: str):
    async for message in websocket:
      try:
        request: Request = json.loads(message)
        logger.info(f'JSON-RPC request: {request}')
        if 'method' in request:
          method = request['method']
          params = request.get('params', [])
          command = f"{method} {' '.join(params)}"
          logger.info(f'Executing command: {command}')
          response = send_vlc_command(command)
          if response:
            await send_response(websocket, request.get('id'), result = response)
        else:
          await send_response(websocket, request.get('id'), error = {
            'code': 400,
            'message': 'Invalid JSON-RPC request',
          })
      except Exception as error:
        logger.error(f'Error processing JSON-RPC request: {str(error)}')
        await send_response(websocket, None, error = {
          'code': 500,
          'message': 'Unable to process request',
          'data': str(error),
        })

  async def health_check(path: str, request_headers: dict):
    if path == '/health':
      return http.HTTPStatus.OK, [], b'OK\n'

  async def serve():
    server = await websockets.server.serve(
      handle_websocket,
      host = '::',
      port = port,
      process_request = health_check,
      server_header = USER_AGENT,
    )

    await stop
    logger.info('Stoping Oremi Player...')
    server.close(close_connections = False)
    await server.wait_closed()
    logger.info('Closing VLC LUA CLI...')
    vlc_client.close()
    logger.info('Goodbye!')
    sys.exit(0)

  loop.add_signal_handler(signal.SIGINT, stop.set_result, None)
  loop.add_signal_handler(signal.SIGTERM, stop.set_result, None)

  logger.info(f'Starting {USER_AGENT}...')

  try:
    loop.run_until_complete(serve())
    loop.run_forever()
  finally:
    loop.close()
