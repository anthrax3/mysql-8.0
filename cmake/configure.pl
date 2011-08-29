#!/usr/bin/perl
use strict;
use Cwd 'abs_path';
use File::Basename;

my $cmakeargs = "";

# Find source root directory
# Assume this script is in <srcroot>/cmake
my $srcdir = dirname(dirname(abs_path($0)));
my $cmake_install_prefix="";

# Sets installation directory,  bindir, libdir, libexecdir etc
# the equivalent CMake variables are given without prefix
# e.g if --prefix is /usr and --bindir is /usr/bin
# then cmake variable (INSTALL_BINDIR) must be just "bin"

sub set_installdir 
{
   my($path, $varname) = @_;
   my $prefix_length = length($cmake_install_prefix);
   if (($prefix_length > 0) && (index($path,$cmake_install_prefix) == 0))
   {
      # path is under the prefix, so remove the prefix and maybe following "/"
      $path = substr($path, $prefix_length);
      if(length($path) > 0)
      {
        my $char = substr($path, 0, 1);
        if($char eq "/")
        {
          $path= substr($path, 1);
        }
      }
      if(length($path) > 0)
      {
        $cmakeargs = $cmakeargs." -D".$varname."=".$path;
      }
   }
}

# CMake understands CC and CXX env.variables correctly, if they  contain 1 or 2 tokens
# e.g CXX=gcc and CXX="ccache gcc" are ok. However it could have a problem if there
# (recognizing gcc) with more tokens ,e.g CXX="ccache gcc --pipe".
# The problem is simply fixed by splitting compiler and flags, e.g
# CXX="ccache gcc --pipe" => CXX=ccache gcc CXXFLAGS=--pipe

sub check_compiler
{
  my ($varname, $flagsvarname) = @_;
  my @tokens = split(/ /,$ENV{$varname});
  if($#tokens >= 2)  
  {
    $ENV{$varname} = $tokens[0]." ".$tokens[1];
    my $flags;

    for(my $i=2; $i<=$#tokens; $i++)
    {
      $flags= $flags." ".$tokens[$i];  
    }
    if(defined $ENV{$flagsvarname})
    {
      $flags = $flags." ".$ENV{$flagsvarname};
    }
    $ENV{$flagsvarname}=$flags;
    print("$varname=$ENV{$varname}\n");
    print("$flagsvarname=$ENV{$flagsvarname}\n");
  }  
}

check_compiler("CC", "CFLAGS");
check_compiler("CXX", "CXXFLAGS");

foreach my $option (@ARGV)
{
  if (substr ($option, 0, 2) eq "--")
  {
    $option = substr($option, 2);
  }
  else
  {
    # This must be environment variable
    my @v  = split('=', $option);
    my $name = shift(@v);
    if(@v)
    {
      $ENV{$name} = join('=', @v);  
    }	
    next;
  }
  if($option =~ /srcdir/)
  {
    $srcdir = substr($option,7);
    next;
  }
  if($option =~ /help/)
  {
    system("cmake ${srcdir} -LH");
    exit(0);
  }
  if($option =~ /with-plugins=/)
  {
    my @plugins= split(/,/, substr($option,13));
    foreach my $p (@plugins)
    {
      $p =~ s/-/_/g;
      $cmakeargs = $cmakeargs." -DWITH_".uc($p)."=1";
    }
    next;
  }
  if($option =~ /with-extra-charsets=/)
  {
    my $charsets= substr($option,20);
    $cmakeargs = $cmakeargs." -DWITH_EXTRA_CHARSETS=".$charsets;
    next;
  }
  if($option =~ /without-plugin=/)
  {
    $cmakeargs = $cmakeargs." -DWITHOUT_".uc(substr($option,15))."=1";
    next;
  }
  if($option =~ /with-zlib-dir=bundled/)
  {
    $cmakeargs = $cmakeargs." -DWITH_ZLIB=bundled";
    next;
  }
  if($option =~ /with-zlib-dir=/)
  {
    $cmakeargs = $cmakeargs." -DWITH_ZLIB=system";
    next;
  }
  if($option =~ /with-ssl=/)
  {
    $cmakeargs = $cmakeargs." -DWITH_SSL=yes";
    next;
  }
  if($option =~ /with-ssl/)
  {
    $cmakeargs = $cmakeargs." -DWITH_SSL=bundled";
    next;
  }
  if($option =~ /prefix=/)
  {
    $cmake_install_prefix= substr($option, 7);
    $cmakeargs = $cmakeargs." -DCMAKE_INSTALL_PREFIX=".$cmake_install_prefix;
    next;
  }
  if($option =~/bindir=/)
  {
    set_installdir(substr($option,7), "INSTALL_BINDIR");
    next;
  }
  if($option =~/libdir=/)
  {
    set_installdir(substr($option,7), "INSTALL_LIBDIR");
    next;
  }
  if($option =~/libexecdir=/)
  {
    set_installdir(substr($option,11), "INSTALL_SBINDIR");
    next;
  }
  if($option =~/includedir=/)
  {
    set_installdir(substr($option,11), "INSTALL_INCLUDEDIR");
    next;
  }
  if ($option =~ /extra-charsets=all/)
  {
    $cmakeargs = $cmakeargs." -DWITH_CHARSETS=all"; 
    next;
  }
  if ($option =~ /extra-charsets=complex/)
  {
    $cmakeargs = $cmakeargs." -DWITH_CHARSETS=complex"; 
    next;
  }
  if ($option =~ /localstatedir=/)
  {
    $cmakeargs = $cmakeargs." -DMYSQL_DATADIR=".substr($option,14); 
    next;
  }
  if ($option =~ /mysql-maintainer-mode/)
  {
    $cmakeargs = $cmakeargs." -DMYSQL_MAINTAINER_MODE=" .
                 ($option =~ /enable/ ? "1" : "0");
    next;
  }
  if ($option =~ /with-comment=/)
  {
    $cmakeargs = $cmakeargs." \"-DWITH_COMMENT=".substr($option,13)."\""; 
    next;
  }
  if ($option =~ /with-classpath=/)
  {
    $cmakeargs = $cmakeargs." \"-DWITH_CLASSPATH=".substr($option,15)."\"";
    next;
  }
  if ($option =~ /with-debug=/)
  {
    $cmakeargs = $cmakeargs." -DWITH_DEBUG=1";
    next;
  }
  if ($option =~ /with-ndb-ccflags=/)
  {
    $cmakeargs = $cmakeargs." \"-DWITH_NDB_CCFLAGS=".substr($option,17)."\"";
    next;
  if ($option =~ /with-gcov/)
  {
      $cmakeargs = $cmakeargs." -DENABLE_GCOV=ON"; 
      next;
  }

  $option = uc($option);
  $option =~ s/-/_/g;
  $cmakeargs = $cmakeargs." -D".$option."=1";
}

print("configure.pl : calling cmake $srcdir $cmakeargs\n");
unlink("CMakeCache.txt");
my $rc = system("cmake $srcdir $cmakeargs");
exit($rc);
