clear;
phase =(12+2*26); %phase shift. L(12) +2*Z(26) = 64
qpskMod = comm.QPSKModulator('PhaseOffset',phase); %qpsk modulation with phase offset of 64
qpskDemod = comm.QPSKDemodulator('PhaseOffset',phase); %qpsk demodulation with phase offset of 64

%define constellation diagrams
refC = 2^0.5*constellation(qpskMod);
constDiagram30 = comm.ConstellationDiagram('Name','SNR30db' , 'ReferenceConstellation', refC);

%define awgn channel with snr 30
awgnchan30 = comm.AWGNChannel('NoiseMethod','Signal to noise ratio (SNR)','SNR',30 );

%PN code generator:

%1st PN sequence for desired message 
pnSequence1_D = comm.PNSequence('Polynomial','x^5+x^2+1','InitialConditions',[1 1 1 1 1],'SamplesPerFrame',31);

%2nd PN sequence for desired message. Sequence delayed by 7.
%(L(12)+Z(26))mod31=7. 
pnSequence2_D = comm.PNSequence('Polynomial','x^5+x^3+x^2+x+1','InitialConditions',[1 1 1 1 1],'SamplesPerFrame',31,'Mask', -7 );

%1st PN sequence for jammer
pnSequence1_J = comm.PNSequence('Polynomial','x^5+x^3+1','InitialConditions',[1 1 1 1 1],'SamplesPerFrame',31);

%2nd PN sequence for jammer. Sequence delayed by 8.
pnSequence2_J = comm.PNSequence('Polynomial','x^5+x^4+x^2+x+1','InitialConditions',[1 1 1 1 1],'SamplesPerFrame',31,'Mask', -8 );

%Create gold sequence by adding the two sequences. Converted into +- ones
%using the formula x*-2+1
gold_seq_D = mod((pnSequence1_D()+pnSequence2_D()),2)*-2+1;
gold_seq_J = mod((pnSequence1_J()+pnSequence2_J()),2)*-2+1;

% define data and jammer
data = 'A huge new leak of financial documents has revealed how the powerful and ultra-wealthy, including the Queens private estate, secretly invest vast amounts of cash in offshore tax havens. Donald Trumps commerce secretary is shown to have a stake in a firm dealing with Russians sanctioned by the US. hi';
jammer = 'This is a free online calculator which counts the number of characters or letters in a text, useful for your tweets on Twitter, as well as a multitude of other applications. Whether it is Snapchat, Facebook or just a note to co-workers or business officials, the number of actual characters matters. ';

% source encoder. change each character into an 8-bit integer
dataArray = uint8(data);
jammerArray = uint8(jammer);
databits = [] ;
jammerbits = [];

for i=1:300
    a =bitget(dataArray(i),8:-1:1);
    b = bitget(jammerArray(i), 8:-1:1);
    databits = [databits a];
    jammerbits = [jammerbits b];
end

%digital modulator & spreader
qpskTx_data = [];
jammerTx = [];
qpskTx_jammer=[];

for j=1:2:2400
    datatx = databits(j)*2 + databits(j+1);
    jammertx = jammerbits(j)*2 + jammerbits (j+1);
    %multiply the message and jammer bits with their corresponding gold
    %sequence. 31 pn codes used to encode one message bit. PG = 31
    qpskTx_data=[qpskTx_data 2^0.5*qpskMod(datatx)*gold_seq_D.'];
    qpskTx_jammer = [qpskTx_jammer 20^0.5*qpskMod(jammertx)*gold_seq_J.'];
end

%Add PN encoded jammer and desired message
qpskTx_dataandjammer = qpskTx_data + qpskTx_jammer;


%AWGN channel noise
signalwithnoise30 = awgnchan30(qpskTx_dataandjammer);

%depreading the signal. 
despread=[];
for k=1:31:length(signalwithnoise30)
    %Correlation
    x = sum(signalwithnoise30(k:k+30).* gold_seq_D.');
    despread = [despread x];
end


%digital demodulator
qpskRx30 = [];

for j=1:1200    
    qpskRx30=[qpskRx30 qpskDemod(despread(j))];
end

%plot constellation diagram
constDiagram30(transpose(despread));

%source decoder
eightbitarray30 = [];

for j=1:4:1200
    eightbitint30 = qpskRx30(j)*2^6 + qpskRx30(j+1)*2^4+qpskRx30(j+2)*2^2+qpskRx30(j+3);
    eightbitarray30 =[ eightbitarray30 eightbitint30 ];

end

%print output message
decoded30 = char(eightbitarray30)




