clc;clear 
%% ����ԭʼ��Ϣ����
simulation_point = 1000000;
R_b = 100000;%R_b=100kbps
F_s = 400000;%�趨Frequency of Sampling = 400kbps
source_data = randsrc(1,simulation_point,[1,0]);%����ԭʼ����
%% �������
trellis = poly2trellis(9,[561 753]);
conv_data = convenc(source_data,trellis);
%% ��֯
rows = 10;cols = 100;%�趨��֯���������
division = length(conv_data)/(rows*cols);%��֯����
interwine_data = zeros(1,2*simulation_point);
for i =1:division
    temp_data_1 = conv_data(1,(((i-1)*(rows*cols))+1):(i*(rows*cols)));
    temp_data_2 = matintrlv(temp_data_1,rows,cols);
    interwine_data(1:i*rows*cols) = horzcat(interwine_data(1:(i-1)*rows*cols),temp_data_2);
end
%% BPSK����
send_data = interwine_data;
send_data(send_data ==0) = -1;%��01����ת��Ϊ1��-1����
for i = 1:(2*simulation_point)
    sample_data((i-1)*2+1:i*2) = send_data(i);%Ҫ���͵�����
end
%% AWGN�ŵ�
EbN0 = 0:10;%ȡ0~10dB 
N0 = 0.5*(F_s/(2*R_b))*10.^(-EbN0/10);%�����������������
%��R_b�Ǳ�R_b��
BERH=zeros(1,11);
BERS=zeros(1,11);
Hdeinterwine_data=zeros(1,2*simulation_point);
for i =1:11
    noise = sqrt(N0(i)).*randn(1,4*simulation_point);%�����������������
    handle_data = sample_data + noise;
    %% ���
    receive_data=zeros(1,2*10^6);
    for j = 1:(2*simulation_point)
        receive_data(j) = sum(handle_data(((j-1)*2+1):(j*2)));%ƥ���˲�
    end
    %% �⽻֯
    deinterwine_data = zeros(1,2*simulation_point);
    for k = 1:division
        temp_data_1 = receive_data(1,(((k-1)*(rows*cols))+1):(k*(rows*cols)));
        temp_data_2 = matdeintrlv(temp_data_1,rows,cols);
        deinterwine_data(1:k*rows*cols) = horzcat(deinterwine_data(1:(k-1)*rows*cols),temp_data_2);
    end
    %% ����
    Hdeinterwine_data(deinterwine_data>=0)=1;
    Hdeinterwine_data(deinterwine_data<0)=0;
    nsdec=3;%����������
    llim=min(min(deinterwine_data));
    rlim=max(max(deinterwine_data));
    partition=linspace(llim,rlim,2^nsdec+1);
    partition(1)=[];partition(end)=[];
    Sdeinterwine_data = quantiz(deinterwine_data,partition);
    tbdepth=5;%A rate 1/2 code has a traceback depth of 5(ConstraintLength �C 1).
    Hdeconv_data=vitdec(Hdeinterwine_data,trellis,tbdepth,'trunc','hard');%Ӳ�о�
    Sdeconv_data=vitdec(Sdeinterwine_data,trellis,tbdepth,'trunc','soft',nsdec);%r���о�
    BERH(i) = biterr(Hdeconv_data,source_data)/simulation_point;
    BERS(i) = biterr(Sdeconv_data,source_data)/simulation_point;
end

figure
semilogy(0:10,BERH,'bx-');hold on
semilogy(0:10,BERS,'ro-');hold off
legend('Ӳ�о�','���о� '); 
xlabel('E/N(dB)');ylabel('������Pe'); 
grid on
title('AWGN�ŵ���Ӳ�о������о��������뷽ʽ��������')