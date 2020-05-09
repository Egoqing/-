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
%% ��֯----���ֽ�֯��ȣ�100��1000��10000
rows1 = 100;rows2=1000;rows3=10000;cols = 10;%�趨��֯���������

division1 = length(conv_data)/(rows1*cols);%��֯����
division2 = length(conv_data)/(rows2*cols);%��֯����
division3 = length(conv_data)/(rows3*cols);%��֯����

interwine_data1 = zeros(1,2*simulation_point);
interwine_data2 = zeros(1,2*simulation_point);
interwine_data3 = zeros(1,2*simulation_point);

for i =1:division1
    temp_data_1 = conv_data(1,(((i-1)*(rows1*cols))+1):(i*(rows1*cols)));
    temp_data_2 = matintrlv(temp_data_1,rows1,cols);
    interwine_data1(1:i*rows1*cols) = horzcat(interwine_data1(1:(i-1)*rows1*cols),temp_data_2);
end

for i =1:division2
    temp_data_1 = conv_data(1,(((i-1)*(rows2*cols))+1):(i*(rows2*cols)));
    temp_data_2 = matintrlv(temp_data_1,rows2,cols);
    interwine_data2(1:i*rows2*cols) = horzcat(interwine_data2(1:(i-1)*rows2*cols),temp_data_2);
end

for i =1:division3
    temp_data_1 = conv_data(1,(((i-1)*(rows3*cols))+1):(i*(rows3*cols)));
    temp_data_2 = matintrlv(temp_data_1,rows3,cols);
    interwine_data3(1:i*rows3*cols) = horzcat(interwine_data3(1:(i-1)*rows3*cols),temp_data_2);
end
%% BPSK����
send_data1 = interwine_data1;%�н�֯
send_data2 = interwine_data2;%�޽�֯
send_data3 = interwine_data3;

send_data1(send_data1 ==0) = -1;%��01����ת��Ϊ1��-1����
send_data2(send_data2 ==0) = -1;%��01����ת��Ϊ1��-1����
send_data3(send_data3 ==0) = -1;%��01����ת��Ϊ1��-1����

sample_data1=zeros(1,4*simulation_point);
sample_data2=zeros(1,4*simulation_point);
sample_data3=zeros(1,4*simulation_point);

for i = 1:2*simulation_point
    sample_data1((i-1)*2+1:i*2) = send_data1(i);%Ҫ���͵�����
    sample_data2((i-1)*2+1:i*2) = send_data2(i);%Ҫ���͵�����
    sample_data3((i-1)*2+1:i*2) = send_data3(i);%Ҫ���͵�����
end
%% ����Rayleigh�ŵ�
fd = 100; %��������Ƶ��
h=ones(1,2*simulation_point);
num=2*R_b/fd;%���ʱ���ڱ��������bit��
division4=2*simulation_point/(2*R_b/fd);
for i=1:division4
    temp_h = sqrt(1/2)*(randn(1,1)+1i*randn(1,1));%����˹�ֲ�
    h((i-1)*num+1:i*num)=abs(temp_h);%������������ֲ�
end
for i = 1:2*simulation_point
    h_data((i-1)*2+1:i*2) = h(i);
end
EbN0 = 0:10;%ȡ0~10dB 
N0 = 0.5*(F_s/(2*R_b))*10.^(-EbN0/10);%�����������������
BER=zeros(3,length(EbN0));  
Hdeinterwine_data=zeros(3,2*simulation_point); 
for i =1:length(EbN0)
    noise = sqrt(N0(i)).*randn(1,4*simulation_point);%�����������������
    handle_data(1,:) = sample_data1.*h_data+noise; 
    handle_data(2,:) = sample_data2.*h_data+noise; 
    handle_data(3,:) = sample_data3.*h_data+noise;
    %% ���
    receive_data=zeros(3,2*simulation_point); %�н�֯
    for j = 1:(2*simulation_point)
        receive_data(1,j) = sum(handle_data(1,((j-1)*2+1):(j*2)));%ƥ���˲�
        receive_data(2,j) = sum(handle_data(2,((j-1)*2+1):(j*2)));%ƥ���˲�
        receive_data(3,j) = sum(handle_data(3,((j-1)*2+1):(j*2)));%ƥ���˲�
    end
    %% �⽻֯
    deinterwine_data = zeros(3,2*simulation_point);
    for k = 1:division1
        temp_data_1 = receive_data(1,(((k-1)*(rows1*cols))+1):(k*(rows1*cols)));
        temp_data_2 = matdeintrlv(temp_data_1,rows1,cols);
        deinterwine_data(1,1:k*rows1*cols) = horzcat(deinterwine_data(1,1:(k-1)*rows1*cols),temp_data_2);
    end
    for k = 1:division2
        temp_data_1 = receive_data(2,(((k-1)*(rows2*cols))+1):(k*(rows2*cols)));
        temp_data_2 = matdeintrlv(temp_data_1,rows2,cols);
        deinterwine_data(2,1:k*rows2*cols) = horzcat(deinterwine_data(2,1:(k-1)*rows2*cols),temp_data_2);
    end
    for k = 1:division3
        temp_data_1 = receive_data(3,(((k-1)*(rows3*cols))+1):(k*(rows3*cols)));
        temp_data_2 = matdeintrlv(temp_data_1,rows3,cols);
        deinterwine_data(3,1:k*rows3*cols) = horzcat(deinterwine_data(3,1:(k-1)*rows3*cols),temp_data_2);
    end
%% ����
    Hdeinterwine_data(1,deinterwine_data(1,:)>=0)=1;
    Hdeinterwine_data(1,deinterwine_data(1,:)<0)=0;
    Hdeinterwine_data(2,deinterwine_data(2,:)>=0)=1;
    Hdeinterwine_data(2,deinterwine_data(2,:)<0)=0;
    Hdeinterwine_data(3,deinterwine_data(3,:)>=0)=1;
    Hdeinterwine_data(3,deinterwine_data(3,:)<0)=0;
    
    tbdepth=5;
    Hdeconv_data(1,:)=vitdec(Hdeinterwine_data(1,:),trellis,tbdepth,'trunc','hard');%Ӳ�о�
    Hdeconv_data(2,:)=vitdec(Hdeinterwine_data(2,:),trellis,tbdepth,'trunc','hard');%Ӳ�о�
    Hdeconv_data(3,:)=vitdec(Hdeinterwine_data(3,:),trellis,tbdepth,'trunc','hard');%Ӳ�о�
    
    BER(1,i) = biterr(Hdeconv_data(1,:),source_data)/simulation_point;
    BER(2,i) = biterr(Hdeconv_data(2,:),source_data)/simulation_point;
    BER(3,i) = biterr(Hdeconv_data(3,:),source_data)/simulation_point;
end
figure
semilogy(EbN0,BER(1,:),'gd-');hold on
semilogy(EbN0,BER(2,:),'bo-');
semilogy(EbN0,BER(3,:),'r^-');
legend('���100','���1000 ','���10000'); 
xlabel('E/N(dB)');ylabel('������Pe'); 
grid on
title('Rayleigh�ŵ���ͬ��֯����µ���������')