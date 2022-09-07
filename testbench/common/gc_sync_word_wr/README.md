This is a testbench for gc_sync_word_wr, which is a synchronizer for writing a word with an ack. The core is used to transfer a word from the input clock domain to the output clock domain.  

Random data provided alongside with a pulse write signal to transfer the data. When the data is transfered, a write pulse is generated on the output side along with the data and an acknowledge is generated on the input side. Once the user requests a transfer, no new data should be requested for a transfer until the ack is received. A busy flag is also available for this purpose (user should not push new data if busy).

Self-checking process: Check that the output data is the same as the input data (for both test cases, when g_auto_wr is either false or true).
Another assertion is used in every rising clock that Acknowledge and Write signal are not equal and also that acknowledge is not equal with busy signal.

Simple coverage is implemented to cover if the reset signals have been asserted. Test is passing when all assertions are not violated.
