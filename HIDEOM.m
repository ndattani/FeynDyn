clear('all')
%% 1. fundamental constants
kb=1.3806504*10^(-23);        % Joules / Kelvin
hbar=1.054571628*10^(-34);    % Joule * seconds

%% 2. temperature
temperature=25;
beta=1/(kb*temperature);

%% 3. system hamiltonian
Omega=hbar*1e12*pi/8;         % Rabi frequency in Joules
H=[0 Omega/2; Omega/2 0];     % System hamiltonian in Joules
M=length(H);

V=[1 0 ; 0 -1];

%% 4. spectral distribution function
alpha=0.027*pi;               % prefactor. In ps^2 / rad^2
wc=2.2;                       % cutoff frequency. In rad/ps
dw=0.01;                      % stepsize for w in J(w). In rad/ps
w_beforeExpand=dw:dw:14;                   % must start with dw because coth(0)=infinity. In rad/ps
w_beforeExpand=[-fliplr(w_beforeExpand) w_beforeExpand];   % need to get rid of middle value (w=0 occurs twice)
w=expand(w_beforeExpand,[M,M]);  % seems it can run out of memory before the HEOM even begins!

J=alpha*exp(-(w/wc).^2).*w.^3;% spectral density. In rad/ps

J=J*1e12*hbar;                % spectral distribution function. In Joules

w=w*1e12;                     % w in s-1
dw=dw*1e12;                   % dw in s-1

ThetaRe=(1/hbar)*J.*coth(beta*hbar*w/2);
ThetaIm=(1/hbar)*J;

H=expand(H,[1,length(w)/M]);
V=expand(V,[1,length(w)/M]);

%% 5. time mesh
finalPoint=100;           % number of timesteps in total
totalT=30/1e12;           % total time for the simulation, in seconds
dt=totalT/finalPoint;
t=0:dt:totalT;

%% 6. intialize rho and ADOs
%rho=zeros(M,M,length(t));rho(1)=1;
rho_beforeReshape=zeros(M,M,length(t),length(w)/M);rho_beforeReshape(1)=1;
rho_w1_beforeReshape=zeros(M,M,length(w)/M);

rho_w1=reshape(rho_w1_beforeReshape,M,[]);
for ii=1:length(t)
    rho=reshape(rho_beforeReshape(:,:,ii,:),M,[]);
    
    rho_w1_next=rho_w1+(dt/hbar)*(-1i*(ThetaRe.*(V.*rho-rho.*V)+ThetaIm.*(V.*rho+rho.*V)+H.*rho_w1-rho_w1.*H+w.*rho_w1)); %ThetaRe*(V*rho(:,:,ii) takes up more memory than needed
    rho_beforeReshape(:,:,ii+1,:)=reshape(rho-(1i/hbar)*(H.*rho-rho.*H+hbar*expand(reshape(trapz(w_beforeExpand,reshape(V.*rho_w1,length(w_beforeExpand),[])),M,M),[1,length(w)/M])-hbar*expand(reshape(trapz(w_beforeExpand,reshape(rho_w1.*V,length(w_beforeExpand),[])),M,M),[1,length(w)/M])),M,M,[]);
    rho_w1=rho_w1_next;
end