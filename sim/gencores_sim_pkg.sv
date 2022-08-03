
package gencores_sim_pkg;

  `include "gencores_sim_defs.svh"

  virtual class CBusAccessor;
    static int _null                = 0;
    int        m_default_xfer_size;


    task set_default_xfer_size(int default_size);
      m_default_xfer_size = default_size;
    endtask  // set_default_xfer_size



    pure virtual task automatic writem(input u64_vector_t addr, input u64_vector_t data,
                                       input int size, ref int result = _null);

    pure virtual task automatic readm(input u64_vector_t addr, ref u64_vector_t data,
                                      input int size, ref int result = _null);

    virtual task automatic read(uint64_t addr, ref uint64_t data,
                                input int size = m_default_xfer_size, ref int result = _null);
      int res;
      u64_vector_t aa = '{addr}, da = {0};

      readm(aa, da, size, res);
      data = da[0];
    endtask


    virtual task automatic write(uint64_t addr, uint64_t data, input int size = m_default_xfer_size,
                                 ref int result = _null);
      u64_vector_t aa = '{addr}, da = {data};
      writem(aa, da, size, result);
    endtask

  endclass  // CBusAccessor

  class CSimUtils;

    static function automatic u64_vector_t pack(input u8_vector_t x, int size, int big_endian = 1);
      u64_vector_t tmp;
      int i, j;
      int nwords, nbytes;

      nwords = (x.size() + size - 1) / size;

      for (i = 0; i < nwords; i++) begin
        uint64_t d;
        d      = 0;
        nbytes = (x.size() - i * nbytes > size ? size : x.size() - i * nbytes);

        for (j = 0; j < nbytes; j++) begin
          if (big_endian) d = d | ((x[i*size+j] << (8 * (size - 1 - j))));
          else d = d | ((x[i*size+j] << (8 * j)));
        end


        tmp.push_back( d );
      end
      return tmp;
    endfunction  // pack


    static function automatic u8_vector_t unpack(input u64_vector_t x, int entry_size, int size,
                                                 int big_endian = 1);
      u8_vector_t tmp;
      int i, n;

      n   = 0;
      i   = 0;


      while (n < size) begin
        tmp.push_back( x[i] >> (8 * (entry_size - 1 - (n % entry_size))) );

        n++;
        if (n % entry_size == 0) i++;
      end

      return tmp;
    endfunction  // unpack
  endclass
    
  class CBusDevice;
    protected CBusAccessor m_acc;
    protected uint64_t m_base;

    function new(CBusAccessor acc, uint64_t base);
      m_acc  = acc;
      m_base = base;
    endfunction  // new

    virtual task automatic writel(uint32_t addr, uint32_t val);
      m_acc.write(m_base + addr, val);
    endtask  // writel


    virtual task automatic readl(uint32_t addr, output uint32_t val);
      automatic uint64_t val64;
      m_acc.read(m_base + addr, val64);
      val = val64;
    endtask  // readl


  virtual task automatic set_bits(uint32_t addr, uint32_t bits);
    uint32_t r;
    readl(addr, r);
    r |= bits;
    writel(addr, r);
  endtask

  virtual task automatic clear_bits(uint32_t addr, uint32_t bits);
    uint32_t r;
    readl(addr, r);
    r &= ~bits;
    writel(addr, r);
  endtask

  endclass  // CBusDevice



  virtual class CMonitorableMemory;

    parameter g_MAX_WIDTH = 1024;
    protected int m_width;

    typedef bit [g_MAX_WIDTH-1:0] mem_array_t[uint32_t];
    mem_array_t m_mem;



    function new(int width);
      m_width = width;
    endfunction  // new


    virtual task automatic read_mem(uint32_t addr, int d_size, int count, output uint64_t data[$]);
      int i;
      int word_size = m_width / 8;

      data = '{};

      for (i = 0; i < count; i++) begin
        uint32_t a = (addr + i * d_size) / word_size * word_size;
        uint32_t shift = (word_size - d_size - ((addr + i * d_size) % word_size)) * 8;
        uint32_t mask = ((1 << (8 * d_size)) - 1);

        //	   $display("RD %x addr %x shift %x mask %x res %04x", m_mem[a], a, shift, mask, (m_mem[a] >> shift) & mask );

        data.push_back((m_mem[a] >> shift) & mask);
      end
    endtask  // read_mem


    pure virtual task automatic reset();
    pure virtual task automatic run();

  endclass  // CMonitorableMemory


    `include "logger.svh"


    static CSimUtils SimUtils;

  
  


endpackage
