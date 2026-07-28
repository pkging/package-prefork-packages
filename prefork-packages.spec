%global debug_package %{nil}

Name:           prefork-packages
Version:        1.0.0
Release:        1%{?dist}
Summary:        Repository configuration for packages.private.prefork.de
License:        MIT
URL:            https://packages.private.prefork.de
Source0:        prefork-packages.asc
BuildArch:      noarch

%description
Repository package that configures Prefork package repositories.

%install
install -d %{buildroot}%{_sysconfdir}/yum.repos.d
install -d %{buildroot}%{_sysconfdir}/pki/rpm-gpg
install -m 0644 %{SOURCE0} %{buildroot}%{_sysconfdir}/pki/rpm-gpg/prefork-packages.asc

%if 0%{?fedora}
cat > %{buildroot}%{_sysconfdir}/yum.repos.d/prefork-packages.repo <<'EOF'
[prefork-packages]
name=Fedora prefork-packages
baseurl=https://packages.private.prefork.de/fedora/$releasever/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/prefork-packages.asc
EOF
%else
cat > %{buildroot}%{_sysconfdir}/yum.repos.d/prefork-packages.repo <<'EOF'
[prefork-packages]
name=EPEL prefork-packages
baseurl=https://packages.private.prefork.de/epel/$releasever/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/prefork-packages.asc
EOF
%endif

%files
%config(noreplace) %{_sysconfdir}/yum.repos.d/prefork-packages.repo
%config(noreplace) %{_sysconfdir}/pki/rpm-gpg/prefork-packages.asc

%changelog
* Tue Jul 28 2026 Lennart Betz <lbetz@prefork.de> 1.0.0-1
- Initial repository package for packages.private.prefork.de
