%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% File:        normal_velocity_TVDRK3_2d.m
% Copyright:   (c) 2005-2008 Kevin T. Chu and Masa Prodanovic
% Revision:    $Revision: 1.2 $
% Modified:    $Date: 2006/09/18 20:32:04 $
% Description: MATLAB test program for level set evolution functions
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This script tests level set evolution functions when the motion of the 
% zero level set is driven in the normal direction by curvature.
%
% The initial condition is the signed distance from the ellipse:
%
%    x.^2 + 0.1*y.^2 = 0.05
%
% The boundary conditions are periodic in both coordinate directions.
%
% In this code, time advection is done using TVD RK3. 
%
% NOTES:
% - All data arrays are in the ordered generated by the MATLAB meshgrid()
%   function.  That is, the data corresponding to the point (x_i,y_j)
%   is stored at index (j,i).  This affects how the ghostcell values are 
%   set.
%
% Kevin Chu
% MAE, Princeton University
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% setup environment
clear
format long

% set up spatial grid parameters
Nx = 100;
Ny = 100;
spatial_derivative_order = 5;
ghostcell_width = 3;
Nx_with_ghostcells = Nx+2*ghostcell_width;
Ny_with_ghostcells = Ny+2*ghostcell_width;
x_lo = -1;
x_hi = 1;
y_lo = -1;
y_hi = 1;
dx = (x_hi-x_lo)/Nx;
dy = (y_hi-y_lo)/Ny;
dX = [dx dy];
X = (x_lo-(ghostcell_width-0.5)*dx:dx:x_hi+ghostcell_width*dx)';
Y = (y_lo-(ghostcell_width-0.5)*dy:dy:y_hi+ghostcell_width*dy)';
[x,y] = meshgrid(X,Y);


% set up time integration parameters
cfl_number = 0.4;
dt = cfl_number/(1/dx^2+1/dy^2);
t_start = 0;
t_end = 0.25;

% initialize phi
phi_init = x.^2 + 0.1*y.^2 - 0.05;
phi = phi_init;

% initialize time
t_cur = t_start;

% initialize flag to indicate if color axis has been set
color_axis_set = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% main time integration loop for TVD RK3 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while (t_cur < t_end)

  % fill boundary cells 
  phi(1:ghostcell_width,:) = ...
    phi(Ny+1:ghostcell_width+Ny,:);
  phi(Ny+ghostcell_width+1:end,:) = ...
    phi(ghostcell_width+1:2*ghostcell_width,:);
  phi(:,1:ghostcell_width) = ...
    phi(:,Nx+1:ghostcell_width+Nx);
  phi(:,Nx+ghostcell_width+1:end) = ...
    phi(:,ghostcell_width+1:2*ghostcell_width);

  % compute normal velocity
  phi_x  = (phi(3:end,:) - phi(1:end-2,:))/2/dx;
  phi_y  = (phi(:,3:end) - phi(:,1:end-2))/2/dy;
  phi_xy = (phi_y(3:end,:) - phi_y(1:end-2,:))/2/dx;
  phi_xx = (phi(3:end,:) - 2*phi(2:end-1,:) + phi(1:end-2,:))/dx/dx;
  phi_yy = (phi(:,3:end) - 2*phi(:,2:end-1) + phi(:,1:end-2))/dy/dy;

  phi_x  = phi_x(ghostcell_width-1:end-ghostcell_width+1, ...
                ghostcell_width:end-ghostcell_width);
  phi_y  = phi_y(ghostcell_width:end-ghostcell_width, ...
                ghostcell_width-1:end-ghostcell_width+1);
  phi_xy = phi_xy(ghostcell_width-1:end-ghostcell_width+1, ...
                  ghostcell_width-1:end-ghostcell_width+1);
  phi_xx = phi_xx(ghostcell_width-1:end-ghostcell_width+1, ...
                  ghostcell_width:end-ghostcell_width);
  phi_yy = phi_yy(ghostcell_width:end-ghostcell_width, ...
                  ghostcell_width-1:end-ghostcell_width+1);

  grad_phi = sqrt(phi_x.^2 + phi_y.^2);

  curvature = ( phi_x.*phi_x.*phi_yy ...
              - 2*phi_x.*phi_y.*phi_xy ...
              + phi_y.*phi_y.*phi_xx)./grad_phi.^3;

  velocity{1} = -curvature;

  % advance level set function
  phi_stage1 = advancePhiTVDRK3_Stage1(phi, velocity, ghostcell_width, ...
                                       dX, dt, cfl_number, ...
                                       spatial_derivative_order);

  % fill boundary cells 
  phi(1:ghostcell_width,:) = ...
    phi(Ny+1:ghostcell_width+Ny,:);
  phi(Ny+ghostcell_width+1:end,:) = ...
    phi(ghostcell_width+1:2*ghostcell_width,:);
  phi(:,1:ghostcell_width) = ...
    phi(:,Nx+1:ghostcell_width+Nx);
  phi(:,Nx+ghostcell_width+1:end) = ...
    phi(:,ghostcell_width+1:2*ghostcell_width);

  % compute normal velocity
  phi_x  = (phi_stage1(3:end,:) - phi_stage1(1:end-2,:))/2/dx;
  phi_y  = (phi_stage1(:,3:end) - phi_stage1(:,1:end-2))/2/dy;
  phi_xy = (phi_y(3:end,:) - phi_y(1:end-2,:))/2/dx;
  phi_xx = (phi_stage1(3:end,:) - 2*phi_stage1(2:end-1,:) ...
         + phi_stage1(1:end-2,:))/dx/dx;
  phi_yy = (phi_stage1(:,3:end) - 2*phi_stage1(:,2:end-1) ...
         + phi_stage1(:,1:end-2))/dy/dy;

  phi_x  = phi_x(ghostcell_width-1:end-ghostcell_width+1, ...
                ghostcell_width:end-ghostcell_width);
  phi_y  = phi_y(ghostcell_width:end-ghostcell_width, ...
                ghostcell_width-1:end-ghostcell_width+1);
  phi_xy = phi_xy(ghostcell_width-1:end-ghostcell_width+1, ...
                  ghostcell_width-1:end-ghostcell_width+1);
  phi_xx = phi_xx(ghostcell_width-1:end-ghostcell_width+1, ...
                  ghostcell_width:end-ghostcell_width);
  phi_yy = phi_yy(ghostcell_width:end-ghostcell_width, ...
                  ghostcell_width-1:end-ghostcell_width+1);

  grad_phi = sqrt(phi_x.^2 + phi_y.^2);

  curvature = ( phi_x.*phi_x.*phi_yy ...
              - 2*phi_x.*phi_y.*phi_xy ...
              + phi_y.*phi_y.*phi_xx)./grad_phi.^3;

  velocity{1} = -curvature;

  % advance level set function
  phi_stage2 = advancePhiTVDRK3_Stage2(phi_stage1, phi, ...
                                       velocity, ghostcell_width, ...
                                       dX, dt, cfl_number, ...
                                       spatial_derivative_order);
  % fill boundary cells 
  phi(1:ghostcell_width,:) = ...
    phi(Ny+1:ghostcell_width+Ny,:);
  phi(Ny+ghostcell_width+1:end,:) = ...
    phi(ghostcell_width+1:2*ghostcell_width,:);
  phi(:,1:ghostcell_width) = ...
    phi(:,Nx+1:ghostcell_width+Nx);
  phi(:,Nx+ghostcell_width+1:end) = ...
    phi(:,ghostcell_width+1:2*ghostcell_width);

  % compute normal velocity
  phi_x  = (phi_stage2(3:end,:) - phi_stage2(1:end-2,:))/2/dx;
  phi_y  = (phi_stage2(:,3:end) - phi_stage2(:,1:end-2))/2/dy;
  phi_xy = (phi_y(3:end,:) - phi_y(1:end-2,:))/2/dx;
  phi_xx = (phi_stage2(3:end,:) - 2*phi_stage2(2:end-1,:) ...
         + phi_stage2(1:end-2,:))/dx/dx;
  phi_yy = (phi_stage2(:,3:end) - 2*phi_stage2(:,2:end-1) ...
         + phi_stage2(:,1:end-2))/dy/dy;

  phi_x  = phi_x(ghostcell_width-1:end-ghostcell_width+1, ...
                ghostcell_width:end-ghostcell_width);
  phi_y  = phi_y(ghostcell_width:end-ghostcell_width, ...
                ghostcell_width-1:end-ghostcell_width+1);
  phi_xy = phi_xy(ghostcell_width-1:end-ghostcell_width+1, ...
                  ghostcell_width-1:end-ghostcell_width+1);
  phi_xx = phi_xx(ghostcell_width-1:end-ghostcell_width+1, ...
                  ghostcell_width:end-ghostcell_width);
  phi_yy = phi_yy(ghostcell_width:end-ghostcell_width, ...
                  ghostcell_width-1:end-ghostcell_width+1);

  grad_phi = sqrt(phi_x.^2 + phi_y.^2);

  curvature = ( phi_x.*phi_x.*phi_yy ...
              - 2*phi_x.*phi_y.*phi_xy ...
              + phi_y.*phi_y.*phi_xx)./grad_phi.^3;

  velocity{1} = -curvature;

  % advance level set function
  phi = advancePhiTVDRK3_Stage3(phi_stage2, phi, ...
                                velocity, ghostcell_width, ...
                                dX, dt, cfl_number, ...
                                spatial_derivative_order);

  % update current time
  t_cur = t_cur + dt

  % plot the current level set function and zero level set
  figure(1); clf;
  pcolor(x,y,phi);
  shading interp
  hold on 
  contour(x,y,phi,[0 0],'c','linewidth',2);
  xlabel('x');
  ylabel('y');
  axis([-1 1 -1 1]);
  axis square;
  if (color_axis_set == 0)
    color_axis = caxis;  % save color axis for initial data
  else
    caxis(color_axis);   % set color axis equal to the one for initial data
  end
  drawnow;

end

% plot results
figure(1); clf;
pcolor(x,y,phi);
shading interp
hold on
contour(x,y,phi,[0 0],'c','linewidth',2);
contour(x,y,phi_init,[0 0],'r','linewidth',2);
xlabel('x');
ylabel('y');
axis([-1 1 -1 1]);
axis square;