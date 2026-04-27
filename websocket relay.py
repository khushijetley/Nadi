# OSC to WebSocket relay
# Receives OSC from SuperCollider, broadcasts to browser via WebSocket
# Run this alongside hr_bridge.py

import asyncio
import json
import threading
from pythonosc import dispatcher, osc_server
import websockets

# All connected browser clients
clients = set()

def broadcast(msg_dict):
    data = json.dumps(msg_dict)
    dead = set()
    for ws in clients.copy():
        try:
            asyncio.run_coroutine_threadsafe(ws.send(data), loop)
        except:
            dead.add(ws)
    clients.difference_update(dead)

# OSC handlers — called by SuperCollider
def handle_hr(address, value):
    broadcast({"type": "hr", "value": float(value)})

def handle_raga(address, value):
    broadcast({"type": "raga", "value": str(value)})

def handle_autonomy(address, value):
    broadcast({"type": "autonomy", "value": float(value)})

def handle_phase(address, value):
    broadcast({"type": "phase", "value": str(value)})

def handle_reset(address):
    broadcast({"type": "reset"})

# WebSocket server
async def ws_handler(websocket):
    clients.add(websocket)
    print(f"Browser connected. Total: {len(clients)}")
    try:
        await websocket.wait_closed()
    finally:
        clients.discard(websocket)
        print(f"Browser disconnected. Total: {len(clients)}")

async def ws_server():
    async with websockets.serve(ws_handler, "localhost", 8765):
        print("WebSocket server running on ws://localhost:8765")
        await asyncio.Future()

def run_osc():
    d = dispatcher.Dispatcher()
    d.map("/hr",       handle_hr)
    d.map("/raga",     handle_raga)
    d.map("/autonomy", handle_autonomy)
    d.map("/phase",    handle_phase)
    d.map("/reset",    handle_reset)
    server = osc_server.ThreadingOSCUDPServer(("127.0.0.1", 57200), d)
    print("OSC server listening on port 57200")
    server.serve_forever()

loop = asyncio.new_event_loop()

osc_thread = threading.Thread(target=run_osc, daemon=True)
osc_thread.start()

print("Relay running. Open visualization.html in Chrome.")
print("Ctrl+C to stop.")

loop.run_until_complete(ws_server())
