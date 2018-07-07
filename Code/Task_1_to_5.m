clear;
phase =(12+2*26); %phase shift. L(12) +2*Z(26) = 64
qpskMod = comm.QPSKModulator('PhaseOffset',phase); %qpsk modulation with phase offset of 64
qpskDemod = comm.QPSKDemodulator('PhaseOffset',phase); %qpsk demodulation with phase offset of 64

%define constellation diagrams
refC = 2^0.5*constellation(qpskMod);
constDiagram30 = comm.ConstellationDiagram('Name','SNR30db' , 'ReferenceConstellation', refC);
constDiagram20 = comm.ConstellationDiagram('Name', 'SNR20db', 'ReferenceConstellation', refC);
constDiagram0 = comm.ConstellationDiagram('Name', 'SNR0db', 'ReferenceConstellation', refC);
constDiagramNoiseless = comm.ConstellationDiagram('Name', 'Noiseless', 'ReferenceConstellation', refC);

%define awgn channel with snr of 30, 20 and 0
awgnchan30 = comm.AWGNChannel('NoiseMethod','Signal to noise ratio (SNR)','SNR',30 );
awgnchan20 = comm.AWGNChannel('NoiseMethod','Signal to noise ratio (SNR)','SNR', 20);
awgnchan0 = comm.AWGNChannel('NoiseMethod','Signal to noise ratio (SNR)','SNR',0 );


% define data and jammer
data = 'A huge new leak of financial documents has revealed how the powerful and ultra-wealthy, including the Queens private estate, secretly invest vast amounts of cash in offshore tax havens. Donald Trumps commerce secretary is shown to have a stake in a firm dealing with Russians sanctioned by the US. hi';
jammer = 'This is a free online calculator which counts the number of characters or letters in a text, useful for your tweets on Twitter, as well as a multitude of other applications. Whether it is Snapchat, Facebook or just a note to co-workers or business officials, the number of actual characters matters. ';


% source encoder. change each character into an 8-bit integer
dataArray = uint8(data);
databits = [] ;
for i=1:300
    a =bitget(dataArray(i),8:-1:1);
    databits = [databits a];
end

%digital modulator. QPSK modulation
qpskTx = [];
for j=1:2:2400
    datatx = databits(j)*2 + databits(j+1); %map every 2 bits to one symbol
    qpskTx=[qpskTx 2^0.5*qpskMod(datatx)];
    
end

%AWGN channel noise
signalwithnoise30 = awgnchan30(qpskTx);
signalwithnoise20 = awgnchan20(qpskTx);
signalwithnoise0 = awgnchan0(qpskTx);

%digital demodulator
qpskRxnonoise = [];
qpskRx30 = [];
qpskRx20 = [];
qpskRx0 = [];
qpskRx = [];

for j=1:1200
    qpskRx=[qpskRx qpskDemod(qpskTx(j))];
    qpskRx30=[qpskRx30 qpskDemod(signalwithnoise30(j))];
    qpskRx20=[qpskRx20 qpskDemod(signalwithnoise20(j))];
    qpskRx0=[qpskRx0 qpskDemod(signalwithnoise0(j))];

end

%BER analysis
outputbits = [];

for j=1:1200;
    outputbits = [outputbits bitget(qpskRx(j), 2) bitget(qpskRx(j), 1)];
end

A = databits~=outputbits;
errorbitsnoiseless = sum(A(:)==1);

outputbits = [];

for j=1:1200;
    outputbits = [outputbits bitget(qpskRx30(j), 2) bitget(qpskRx30(j), 1)];
end

B = databits~=outputbits;
errorbits30 = sum(B(:)==1);

outputbits = [];

for j=1:1200;
    outputbits = [outputbits bitget(qpskRx20(j), 2) bitget(qpskRx20(j), 1)];
end

C = databits~=outputbits;
errorbits20 = sum(C(:)==1);

outputbits = [];

for j=1:1200;
    outputbits = [outputbits bitget(qpskRx0(j), 2) bitget(qpskRx0(j), 1)];
end

D = databits~=outputbits;
errorbits0 = sum(D(:)==1);
        
%plot constellation diagram
constDiagramNoiseless(transpose(qpskTx));
constDiagram30(transpose(signalwithnoise30));
constDiagram20(transpose(signalwithnoise20));
constDiagram0(transpose(signalwithnoise0));


%source decoder. convert symbols back to 8-bit integers, then to alphanumeric characters

eightbitarray = [];
eightbitarray30 = [];
eightbitarray20 = [];
eightbitarray0 = [];

for j=1:4:1200
    eightbitint = qpskRx(j)*2^6 + qpskRx(j+1)*2^4+qpskRx(j+2)*2^2+qpskRx(j+3);
    eightbitarray =[ eightbitarray eightbitint ];
    eightbitint30 = qpskRx30(j)*2^6 + qpskRx30(j+1)*2^4+qpskRx30(j+2)*2^2+qpskRx30(j+3);
    eightbitarray30 =[ eightbitarray30 eightbitint30 ];
    eightbitint20 = qpskRx20(j)*2^6 + qpskRx20(j+1)*2^4+qpskRx20(j+2)*2^2+qpskRx20(j+3);
    eightbitarray20 =[ eightbitarray20 eightbitint20 ];
    eightbitint0 = qpskRx0(j)*2^6 + qpskRx0(j+1)*2^4+qpskRx0(j+2)*2^2+qpskRx0(j+3);
    eightbitarray0 =[ eightbitarray0 eightbitint0 ];
end


%Formula for theoretical BER
T_BER = @(EUE) qfunc((2*EUE)^0.5);

%Print decoded message, number of error bits, experimental BER and theoretical BER
data
decoded = char(eightbitarray)
errorbitsnoiseless
BERnoiseless = errorbitsnoiseless/2400
T_BERnoiseless=0

decoded30 = char(eightbitarray30)
errorbits30
BER30 = errorbits30/2400
T_BER30 = T_BER(10^3)

decoded20 = char(eightbitarray20)
errorbits20
BER20 = errorbits20/2400
T_BER20 = T_BER(10^2)

decoded0 = char(eightbitarray0)
errorbits0
BER0 = errorbits0/2400
T_BER0 = T_BER(10^0)


