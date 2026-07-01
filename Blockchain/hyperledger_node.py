import hashlib
import json
import time
from typing import List, Dict, Any
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Hyperledger Fabric Node")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

LEDGER_FILE = "ledger.json"

class TransactionPayload(BaseModel):
    patient_id: str
    timestamp: str
    status: str
    data_hash: str
    color_details: str | None = None

class Blockchain:
    def __init__(self):
        self.chain = []
        self.load_ledger()

    def load_ledger(self):
        if os.path.exists(LEDGER_FILE):
            try:
                with open(LEDGER_FILE, "r") as f:
                    self.chain = json.load(f)
                if not self.chain:
                    self.create_genesis_block()
            except Exception:
                self.create_genesis_block()
        else:
            self.create_genesis_block()

    def save_ledger(self):
        with open(LEDGER_FILE, "w") as f:
            json.dump(self.chain, f, indent=4)

    def create_genesis_block(self):
        genesis_block = {
            "index": 1,
            "timestamp": time.time(),
            "transactions": [],
            "previous_hash": "0" * 64,
            "nonce": 100
        }
        genesis_block["hash"] = self.hash_block(genesis_block)
        self.chain.append(genesis_block)
        self.save_ledger()

    def get_last_block(self):
        return self.chain[-1]

    def hash_block(self, block: Dict[str, Any]) -> str:
        block_string = json.dumps({k: block[k] for k in block if k != 'hash'}, sort_keys=True).encode()
        return hashlib.sha256(block_string).hexdigest()

    def add_transaction(self, tx: TransactionPayload) -> str:
        last_block = self.get_last_block()
        
        # Simulate Hyperledger Fabric transaction ID (tx_id)
        tx_id = hashlib.sha256(f"{tx.patient_id}{time.time()}".encode()).hexdigest()
        
        transaction = {
            "tx_id": tx_id,
            "patient_id": tx.patient_id,
            "timestamp": tx.timestamp,
            "status": tx.status,
            "data_hash": tx.data_hash,
            "color_details": tx.color_details,
            "channel": "ehealth-channel",
            "chaincode": "screening_cc"
        }

        # Create a new block for this transaction (mimicking Fabric's orderer creating a block per batch/tx)
        new_block = {
            "index": last_block["index"] + 1,
            "timestamp": time.time(),
            "transactions": [transaction],
            "previous_hash": last_block["hash"],
            "nonce": 0
        }
        new_block["hash"] = self.hash_block(new_block)
        
        self.chain.append(new_block)
        self.save_ledger()
        return tx_id

    def get_transactions_by_patient(self, patient_id: str) -> List[Dict[str, Any]]:
        txs = []
        for block in self.chain:
            for tx in block["transactions"]:
                if tx["patient_id"] == patient_id:
                    # Append block info for verification
                    tx_copy = dict(tx)
                    tx_copy["block_index"] = block["index"]
                    tx_copy["block_hash"] = block["hash"]
                    txs.append(tx_copy)
        return txs

# Instantiate the blockchain
ledger = Blockchain()

@app.get("/")
def root():
    return {"message": "Hyperledger Fabric Node is Running"}

@app.post("/api/chaincode/invoke")
def invoke_chaincode(payload: TransactionPayload):
    """
    Simulates invoking a chaincode in Hyperledger to save the screening hash.
    """
    tx_id = ledger.add_transaction(payload)
    return {
        "status": "SUCCESS",
        "message": "Transaction committed to ledger",
        "tx_id": tx_id,
        "block_index": ledger.get_last_block()["index"]
    }

@app.get("/api/ledger")
def get_full_ledger():
    """
    For Blockchain Explorer Dashboard. Returns the full chain.
    """
    return {"chain": ledger.chain, "length": len(ledger.chain)}

@app.get("/api/ledger/{patient_id}")
def get_patient_ledger(patient_id: str):
    """
    For Hospital Dashboard Data Validator.
    """
    txs = ledger.get_transactions_by_patient(patient_id)
    if not txs:
        raise HTTPException(status_code=404, detail="No records found in blockchain for this patient")
    return {"transactions": txs}
