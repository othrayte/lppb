# Length Prefixed Protocol Buffer Dissector
Dissects protocol buffer content contained in length prefixed blocks (on tcp connections) and hands them to protobuf_dissector.

This effectivly adds tcp support to protobuf_dissector if using length prefixed blocks.

# Usage
1. Install the protobuf_dissector from github.com/dex/protobuf_dissector
2. Set the port number and schema in the preferences (Edit > Preferences... > Protocols > LPPB)
   The schema should be the same as the name of the protocol that was added by protobuf_dissector
