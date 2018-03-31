<html>
  
<br><br>
Thermo_pw is a set of Fortran drivers for the parallel and/or automatic 
computation of materials properties using Quantum ESPRESSO (QE) routines 
as the underlying engine. It provides an alternative organization of the 
QE work-flow for the most common tasks exploiting, when possible, 
an asynchronous image parallelization. Moreover, the code has a set of 
pre-processing tools to reduce the user input information and a set of 
post-processing tools to produce plots directly comparable with experiment.
<br>
<br>

The user's guide of <code>thermo_pw</code> version <code>0.9.0</code> can be
found <a href="https://people.sissa.it/dalcorso/thermo_pw/user_guide/index.html">here</a>.
<br>
<br>
Presently there is no reference work for citing <code>thermo_pw</code>. If you want to mention it in your work, you can put a reference to this web page.

<br>
<br>

  The following papers have been written using thermo_pw:
<br>
<br>
A. Urru and A. Dal Corso,
Clean Os(0001) electronic surface states: a first-principle fully relativistic investigation,
<a href="https://www.sciencedirect.com/science/article/pii/S0039602817309469">Surf. Sci. <B> 671</B>, 17 (2018).</a>
<br>
<br>
M. Palumbo and A. Dal Corso,
Lattice dynamics and thermophysical properties of h.c.p. Os and Ru from
the quasi-harmonic approximation,
<a href="http://iopscience.iop.org/article/10.1088/1361-648X/aa7dca">
J. of Phys.: Condens. Matter <B>29</B>, 395401 (2017).
</a>

<br>
<br>
M. Palumbo and A. Dal Corso,
Lattice dynamics and thermophysical properties of h.c.p. Re and Tc from
the quasi-harmonic approximation,
<a href="http://dx.doi.org/10.1002/pssb.201700101">Physica Status Solidi B:
Basic Solid State Physics <B>254</B>, 1700101 (2017).
</a>

<br>
<br>
A. Dal Corso,
Elastic constants of Beryllium: a first-principles investigation,
<a href="http://dx.doi.org/10.1088/0953-8984/28/7/075401"> J. Phys.: Condens. Matter <B>28</B>, 075401 (2016) </a>.

<br>
<br>
A. Dal Corso,
Clean Ir(111) and Pt(111) electronic surface states: a first-principle fully relativistic investigation,
<a href="http://www.sciencedirect.com/science/article/pii/S0039602815000734"> Surf. Sci. <B>637-638</B>, 106 (2015)</a>.
<br>
<br>
See also the presentation given at the Quantum-ESPRESSO developers meeting 2017:

<br>
<br>
<a href="https://people.sissa.it/~dalcorso/thermo_pw_2017.pdf">Thermo_pw_2017.pdf</a>
<br>
<br>
and at the Quantum-ESPRESSO developers meeting 2018:
<br>
<br>
<a href="https://people.sissa.it/~dalcorso/thermo_pw_2018.pdf">Thermo_pw_2018.pdf</a>
<br>
<br>
The latest developments of the <code>thermo_pw</code> software can be
followed <a href="https://github.com/dalcorso/thermo_pw/commits/master">here</a>.
<br>
<br>
The <code>git</code> of the project is public. You can download the <code>git</code> version of <code>thermo_pw</code> but its use is not recommended.
Please read the user's guide for information on how to download it or follow the instructions at <a href="https://people.sissa.it/~dalcorso/thermo_pw_help.html">
http://people.sissa.it/~dalcorso/thermo_pw_help.html</a>.
Presently it is compatible with QE 6.2.1 that can be obtained from the QE web site.


<br>
For problems to compile or run <code>thermo_pw</code> or if you think
that you have found a bug, please check the help page mentioned above, apply
all the patches and if your problem is not solved, you can post it to the
<a href="mailto:thermo_pw-forum@lists.quantum-espresso.org">thermo_pw-forum mailing list</a> or e-mail me: <a href="mailto:dalcorso .at. sissa.it">dalcorso .at. sissa.it</a>. To subscribe to the <code>thermo_pw-forum</code> mailing list
click <a href="https://lists.quantum-espresso.org/mailman/listinfo/thermo_pw-forum">here</a>.
<br>
Please do not send me questions about the input of <code>pw.x</code>.
If you are new to QE, please ask to the
<code>users@lists.quantum-espresso.org</code> mailing list or search
in the examples directories.
<br>
<br>

<b>Thermo_pw downloads:</b>
<br>
<br>
- <a href="http://people.sissa.it/%7Edalcorso/thermo_pw/thermo_pw-0.9.0.tar.gz">
thermo_pw-0.9.0.tar.gz</a>  (released 20-12-2017) compatible with QE-6.2.1.
<br>
<br>
- <a href="http://people.sissa.it/%7Edalcorso/thermo_pw/thermo_pw-0.8.0.tgz">
thermo_pw-0.8.0.tar.gz</a>  (released 24-10-2017) compatible with QE-6.2.
<br>
<br>
- <a href="http://people.sissa.it/%7Edalcorso/thermo_pw/thermo_pw-0.8.0-beta.tgz">
thermo_pw-0.8.0-beta.tar.gz</a>  (released 31-08-2017) compatible with QE-6.2-beta.
<br>
<br>
- <a href="http://people.sissa.it/%7Edalcorso/thermo_pw/thermo_pw.0.7.9.tgz">
thermo_pw.0.7.9.tgz</a>  (released 06-07-2017) compatible with QE-6.1.
<br>
<br>
- <a href="http://people.sissa.it/%7Edalcorso/thermo_pw/thermo_pw.0.7.0.tgz">
thermo_pw.0.7.0.tgz</a>  (released 18-03-2017) compatible with QE-6.1.
<br>
<br>
- <a href="http://people.sissa.it/%7Edalcorso/thermo_pw/thermo_pw.0.6.0.tgz">
thermo_pw.0.6.0.tgz</a>  (released 05-10-2016) compatible with QE-6.0.
<br>
<br>
- <a href="http://people.sissa.it/%7Edalcorso/thermo_pw/thermo_pw.0.5.0.tar.gz">
thermo_pw.0.5.0.tar.gz</a>  (released 26-04-2016) compatible with QE-5.4.
<br>
<br>
- <a href="http://people.sissa.it/%7Edalcorso/thermo_pw/thermo_pw.0.4.0.tar.gz">
thermo_pw.0.4.0.tar.gz</a>  (released 23-01-2016) compatible with QE-5.3.
<br>
<br>
- <a href="http://people.sissa.it/%7Edalcorso/thermo_pw/thermo_pw.0.3.0.tar.gz">
thermo_pw.0.3.0.tar.gz</a>  (released 23-06-2015) compatible with QE-5.2.0 and QE-5.2.1.
<br>
<br>
- <a href="http://people.sissa.it/%7Edalcorso/thermo_pw/thermo_pw.0.2.0.tar.gz">
thermo_pw.0.2.0.tar.gz</a>   (released 13-03-2015) compatible with QE-5.1.2.
<br>
<br>
- <a href="http://people.sissa.it/%7Edalcorso/thermo_pw/thermo_pw.0.1.0.tar.gz">
thermo_pw.0.1.0.tar.gz</a>   (released 28-11-2014) compatible with QE-5.1.1.
<br> <br>
<br>
<br>
Please notice that the versions of thermo_pw and of QE must be carefully matched: Version 0.9.0 is for QE 6.2.1, 0.8.0 for QE 6.2, 0.8.0-beta for QE 6.2-beta, 0.7.9 and 0.7.0 for QE 6.1, 0.6.0 for QE 6.0, 0.5.0 for QE 5.4.0, version 0.4.0 for QE 5.3.0, version 0.3.0 for QE 5.2.0 and 5.2.1, version 0.2.0 for QE 5.1.2 and version 0.1.0 for QE 5.1.1.
<br<>br>

</html>