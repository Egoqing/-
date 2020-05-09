%% ����ԭʼ��Ϣ����
clear
clc
simulation_point = 1000000;
R_b = 100000;%R_b=100kbps
F_s = 400000;%�趨Frequency of Sampling = 400kbps
source_data = randsrc(1,simulation_point,[1,0]);%����ԭʼ����
%% �������
trellis = poly2trellis(9,[561 753]);
conv_data = convenc(source_data,trellis);
%% ��֯
rows = 100;cols = 10;%�趨��֯���������
division = length(conv_data)/(rows*cols);%��֯����
interwine_data1 = zeros(1,2*simulation_point);
for i =1:division
    temp_data_1 = conv_data(1,(((i-1)*(rows*cols))+1):(i*(rows*cols)));
    temp_data_2 = matintrlv(temp_data_1,rows,cols);
    interwine_data1(1:i*rows*cols) = horzcat(interwine_data1(1:(i-1)*rows*cols),temp_data_2);
end
interwine_data2=conv_data;
%% BPSK����
send_data1 = interwine_data1;%�н�֯
send_data2 = interwine_data2;%�޽�֯

send_data1(send_data1 ==0) = -1;%��01����ת��Ϊ1��-1����
send_data2(send_data2 ==0) = -1;%��01����ת��Ϊ1��-1����

sample_data1=zeros(1,4*simulation_point);
sample_data2=zeros(1,4*simulation_point);
for i = 1:2*simulation_point
    sample_data1((i-1)*2+1:i*2) = send_data1(i);%Ҫ���͵�����
end
for i = 1:2*simulation_point
    sample_data2((i-1)*2+1:i*2) = send_data2(i);%Ҫ���͵�����
end
%% ����Rayleigh�ŵ�
fd = 100; %��������Ƶ��
h=ones(1,2*simulation_point);
num=2*R_b/fd;%���ʱ���ڱ��������bit��
division2=2*simulation_point/(2*R_b/fd);
for i=1:division2
    temp_h = sqrt(1/2)*(randn(1,1)+1i*randn(1,1));%����˹�ֲ�
    h((i-1)*num+1:i*num)=abs(temp_h);%������������ֲ�
end
for i = 1:2*simulation_point
    h_data((i-1)*2+1:i*2) = h(i);
end
EbN0 = 0:10;%ȡ0~10dB 
N0 = 0.5*(F_s/(2*R_b))*10.^(-EbN0/10);%�����������������
cBERH=zeros(1,length(EbN0)); %�н�֯��Ӳ�о�
cBERS=zeros(1,length(EbN0)); %�н�֯�����о�
BERH=zeros(1,length(EbN0));  %�޽�֯��Ӳ�о�
BERS=zeros(1,length(EbN0));  %�޽�֯�����о�
Hdeinterwine_data1=zeros(1,2*simulation_point); %�н�֯
Hdeinterwine_data2=zeros(1,2*simulation_point); %�޽�֯
for i =1:length(EbN0)
    noise = sqrt(N0(i)).*randn(1,4*simulation_point);%�����������������
    handle_data1 = sample_data1.*h_data+noise; %�н�֯
    handle_data2 = sample_data2.*h_data+noise; %�޽�֯
    
    %% ���
    receive_data1=zeros(1,2*simulation_point); %�н�֯
    receive_data2=zeros(1,2*simulation_point); %�޽�֯
    for j = 1:(2*simulation_point)
        receive_data1(j) = sum(handle_data1(((j-1)*2+1):(j*2)));%ƥ���˲�
    end
    for j = 1:(2*simulation_point)
        receive_data2(j) = sum(handle_data2(((j-1)*2+1):(j*2)));%ƥ���˲�
    end
    %% �⽻֯
    deinterwine_data1 = zeros(1,2*simulation_point);
    for k = 1:division
        temp_data_1 = receive_data1(1,(((k-1)*(rows*cols))+1):(k*(rows*cols)));
        temp_data_2 = matdeintrlv(temp_data_1,rows,cols);
        deinterwine_data1(1:k*rows*cols) = horzcat(deinterwine_data1(1:(k-1)*rows*cols),temp_data_2);
    end
    deinterwine_data2=receive_data2;
    %% ����
    Hdeinterwine_data1(deinterwine_data1>=0)=1;
    Hdeinterwine_data1(deinterwine_data1<0)=0;
    Hdeinterwine_data2(deinterwine_data2>=0)=1;
    Hdeinterwine_data2(deinterwine_data2<0)=0;
    
    nsdec=3;%����������
    llim=min(min(deinterwine_data1));
    rlim=max(max(deinterwine_data1));
    partition=linspace(llim,rlim,2^nsdec+1);
    partition(1)=[];partition(end)=[];
    Sdeinterwine_data1 = quantiz(deinterwine_data1,partition);
    
    llim=min(min(deinterwine_data2));
    rlim=max(max(deinterwine_data2));
    partition=linspace(llim,rlim,2^nsdec+1);
    partition(1)=[];partition(end)=[];
    Sdeinterwine_data2 = quantiz(deinterwine_data2,partition);
    
    tbdepth=5;%A rate 1/2 code has a traceback depth of 5(ConstraintLength �C 1).
    Hdeconv_data1=vitdec(Hdeinterwine_data1,trellis,tbdepth,'trunc','hard');%�н�֯Ӳ�о�
    Hdeconv_data2=vitdec(Hdeinterwine_data2,trellis,tbdepth,'trunc','hard');%�޽�֯Ӳ�о�
    
    Sdeconv_data1=vitdec(Sdeinterwine_data1,trellis,tbdepth,'trunc','soft',nsdec);%�н�֯���о�
    Sdeconv_data2=vitdec(Sdeinterwine_data2,trellis,tbdepth,'trunc','soft',nsdec);%�޽�֯���о�
    
    cBERH(i) = biterr(Hdeconv_data1,source_data)/simulation_point;
    cBERS(i) = biterr(Sdeconv_data1,source_data)/simulation_point;
    BERH(i) = biterr(Hdeconv_data2,source_data)/simulation_point;
    BERS(i) = biterr(Sdeconv_data2,source_data)/simulation_point;

end

figure
semilogy(EbN0,cBERH,'bx-');hold on
semilogy(EbN0,cBERS,'ro-');
semilogy(EbN0,BERH,'b^-.');
semilogy(EbN0,BERS,'r+-.');
legend('�н�֯Ӳ�о�(���100)','�н�֯���о�(3bit) ','�޽�֯Ӳ�о�','�޽�֯���о�(3bit)'); 
xlabel('E/N(dB)');ylabel('������Pe'); 
grid on
title('Rayleigh�ŵ��¸����������������')